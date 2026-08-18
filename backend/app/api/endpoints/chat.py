import json
from datetime import datetime, timezone
from typing import List, Dict, Set, Any, Optional
from fastapi import APIRouter, Depends, HTTPException, status, Query, WebSocket, WebSocketDisconnect
from sqlalchemy.orm import Session, joinedload
from sqlalchemy import func, desc, and_

from app.api import deps
from app.db.session import SessionLocal, get_db
from app.core import security
from app.models.user import User
from app.models.chat import Conversation, ConversationParticipant, ChatMessage
from app.schemas.chat import (
    ConversationResponse,
    ChatMessageResponse,
    ChatMessageCreate,
    ConversationParticipantResponse
)
from app.schemas.user import UserResponse

router = APIRouter()

class ConnectionManager:
    """Manages active WebSocket connections grouped by conversation_id."""
    def __init__(self):
        # Maps conversation_id to set of active WebSocket instances
        self.active_connections: Dict[int, Set[WebSocket]] = {}

    async def connect(self, conversation_id: int, websocket: WebSocket):
        await websocket.accept()
        if conversation_id not in self.active_connections:
            self.active_connections[conversation_id] = set()
        self.active_connections[conversation_id].add(websocket)

    def disconnect(self, conversation_id: int, websocket: WebSocket):
        if conversation_id in self.active_connections:
            self.active_connections[conversation_id].discard(websocket)
            if not self.active_connections[conversation_id]:
                del self.active_connections[conversation_id]

    async def broadcast_to_conversation(self, conversation_id: int, data: dict):
        if conversation_id in self.active_connections:
            # Send message payload to all websockets connected to this conversation
            stale_sockets = set()
            for connection in self.active_connections[conversation_id]:
                try:
                    await connection.send_json(data)
                except Exception:
                    stale_sockets.add(connection)
            
            # Clean up stale sockets if any failed
            for dead in stale_sockets:
                self.active_connections[conversation_id].discard(dead)

manager = ConnectionManager()


@router.get("/conversations", response_model=List[ConversationResponse])
def get_user_conversations(
    current_user: User = Depends(deps.get_current_active_user),
    db: Session = Depends(deps.get_db)
) -> Any:
    """Fetch all conversations for current user with participant details and latest message."""
    user_part_query = db.query(ConversationParticipant.conversation_id).filter(
        ConversationParticipant.user_id == current_user.id
    )

    conversations = db.query(Conversation).options(
        joinedload(Conversation.participants).joinedload(ConversationParticipant.user)
    ).filter(
        Conversation.id.in_(user_part_query)
    ).order_by(desc(Conversation.updated_at)).all()

    result = []
    for conv in conversations:
        # Get last message
        last_msg = db.query(ChatMessage).options(
            joinedload(ChatMessage.sender)
        ).filter(
            ChatMessage.conversation_id == conv.id
        ).order_by(desc(ChatMessage.created_at)).first()

        # Calculate unread count
        user_participant = next((p for p in conv.participants if p.user_id == current_user.id), None)
        unread_count = 0
        if user_participant:
            last_read = user_participant.last_read_at
            query = db.query(func.count(ChatMessage.id)).filter(
                ChatMessage.conversation_id == conv.id,
                ChatMessage.sender_id != current_user.id
            )
            if last_read:
                query = query.filter(ChatMessage.created_at > last_read)
            unread_count = query.scalar() or 0

        # Construct response
        conv_dict = {
            "id": conv.id,
            "is_group": conv.is_group,
            "title": conv.title,
            "created_at": conv.created_at,
            "updated_at": conv.updated_at,
            "participants": [
                {
                    "id": p.id,
                    "user_id": p.user_id,
                    "user": UserResponse.model_validate(p.user),
                    "joined_at": p.joined_at,
                    "last_read_at": p.last_read_at,
                }
                for p in conv.participants
            ],
            "last_message": ChatMessageResponse.model_validate(last_msg) if last_msg else None,
            "unread_count": unread_count
        }
        result.append(conv_dict)

    return result


@router.post("/conversations/direct/{target_user_id}", response_model=ConversationResponse)
def get_or_create_direct_conversation(
    target_user_id: int,
    current_user: User = Depends(deps.get_current_active_user),
    db: Session = Depends(deps.get_db)
) -> Any:
    """Get existing direct conversation between current user and target user, or create new one."""
    if target_user_id == current_user.id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot start a chat with yourself."
        )

    target_user = db.query(User).filter(User.id == target_user_id, User.is_active == True).first()
    if not target_user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Target user not found."
        )

    # Check if a 1-on-1 conversation already exists
    user_conv_ids = db.query(ConversationParticipant.conversation_id).filter(
        ConversationParticipant.user_id == current_user.id
    )

    existing_conv_id = db.query(ConversationParticipant.conversation_id).join(
        Conversation, Conversation.id == ConversationParticipant.conversation_id
    ).filter(
        ConversationParticipant.user_id == target_user_id,
        ConversationParticipant.conversation_id.in_(user_conv_ids),
        Conversation.is_group == False
    ).first()


    if existing_conv_id:
        conv = db.query(Conversation).options(
            joinedload(Conversation.participants).joinedload(ConversationParticipant.user)
        ).filter(Conversation.id == existing_conv_id[0]).first()
    else:
        # Create new conversation
        conv = Conversation(is_group=False)
        db.add(conv)
        db.commit()
        db.refresh(conv)

        # Add participants
        p1 = ConversationParticipant(conversation_id=conv.id, user_id=current_user.id)
        p2 = ConversationParticipant(conversation_id=conv.id, user_id=target_user_id)
        db.add_all([p1, p2])
        db.commit()

        # Reload with participants
        conv = db.query(Conversation).options(
            joinedload(Conversation.participants).joinedload(ConversationParticipant.user)
        ).filter(Conversation.id == conv.id).first()

    last_msg = db.query(ChatMessage).options(
        joinedload(ChatMessage.sender)
    ).filter(
        ChatMessage.conversation_id == conv.id
    ).order_by(desc(ChatMessage.created_at)).first()

    return {
        "id": conv.id,
        "is_group": conv.is_group,
        "title": conv.title,
        "created_at": conv.created_at,
        "updated_at": conv.updated_at,
        "participants": [
            {
                "id": p.id,
                "user_id": p.user_id,
                "user": UserResponse.model_validate(p.user),
                "joined_at": p.joined_at,
                "last_read_at": p.last_read_at,
            }
            for p in conv.participants
        ],
        "last_message": ChatMessageResponse.model_validate(last_msg) if last_msg else None,
        "unread_count": 0
    }


@router.get("/conversations/{conversation_id}/messages", response_model=List[ChatMessageResponse])
def get_conversation_messages(
    conversation_id: int,
    limit: int = Query(50, ge=1, le=100),
    offset: int = Query(0, ge=0),
    current_user: User = Depends(deps.get_current_active_user),
    db: Session = Depends(deps.get_db)
) -> Any:
    """Fetch paginated message history for a conversation."""
    # Ensure current user is participant
    participant = db.query(ConversationParticipant).filter(
        ConversationParticipant.conversation_id == conversation_id,
        ConversationParticipant.user_id == current_user.id
    ).first()
    if not participant:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not a participant in this conversation."
        )

    messages = db.query(ChatMessage).options(
        joinedload(ChatMessage.sender)
    ).filter(
        ChatMessage.conversation_id == conversation_id
    ).order_by(desc(ChatMessage.created_at)).offset(offset).limit(limit).all()

    # Update last_read_at for current user
    participant.last_read_at = datetime.now(timezone.utc)
    db.commit()

    # Return in chronological order
    return list(reversed(messages))


@router.post("/conversations/{conversation_id}/read")
def mark_conversation_read(
    conversation_id: int,
    current_user: User = Depends(deps.get_current_active_user),
    db: Session = Depends(deps.get_db)
) -> Any:
    """Mark conversation as read by current user."""
    participant = db.query(ConversationParticipant).filter(
        ConversationParticipant.conversation_id == conversation_id,
        ConversationParticipant.user_id == current_user.id
    ).first()
    if participant:
        participant.last_read_at = datetime.now(timezone.utc)
        db.commit()
    return {"message": "Conversation marked as read"}


@router.websocket("/ws/{conversation_id}")
async def websocket_chat_endpoint(
    websocket: WebSocket,
    conversation_id: int,
    token: str = Query(...),
    db: Session = Depends(deps.get_db)
):
    """
    WebSocket endpoint for real-time messaging.
    Requires token query parameter (JWT Bearer token).
    """
    try:
        # Authenticate user from query token
        payload = security.decode_jwt(token)
        if not payload or payload.get("type") != "access":
            await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
            return

        user_id_str = payload.get("sub")
        if not user_id_str:
            await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
            return

        user_id = int(user_id_str)
        user = db.query(User).filter(User.id == user_id, User.is_active == True).first()
        if not user:
            await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
            return

        # Check conversation membership
        participant = db.query(ConversationParticipant).filter(
            ConversationParticipant.conversation_id == conversation_id,
            ConversationParticipant.user_id == user.id
        ).first()
        if not participant:
            await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
            return

        # Connect WebSocket
        await manager.connect(conversation_id, websocket)

        try:
            while True:
                data_str = await websocket.receive_text()
                try:
                    data = json.loads(data_str)
                except Exception:
                    data = {"content": data_str}

                content = data.get("content", "").strip()
                if not content:
                    continue

                # Save message to database
                msg = ChatMessage(
                    conversation_id=conversation_id,
                    sender_id=user.id,
                    content=content
                )
                db.add(msg)

                # Update conversation updated_at timestamp
                conv = db.query(Conversation).filter(Conversation.id == conversation_id).first()
                if conv:
                    conv.updated_at = datetime.now(timezone.utc)

                # Update sender's last_read_at
                participant.last_read_at = datetime.now(timezone.utc)

                db.commit()
                db.refresh(msg)

                # Reload message with sender relationship
                msg = db.query(ChatMessage).options(
                    joinedload(ChatMessage.sender)
                ).filter(ChatMessage.id == msg.id).first()

                payload_to_broadcast = {
                    "type": "chat_message",
                    "data": {
                        "id": msg.id,
                        "conversation_id": msg.conversation_id,
                        "sender_id": msg.sender_id,
                        "content": msg.content,
                        "created_at": msg.created_at.isoformat(),
                        "sender": {
                            "id": user.id,
                            "username": user.username,
                            "email": user.email,
                            "full_name": user.full_name,
                        }
                    }
                }

                # Broadcast to all connected sockets in this room
                await manager.broadcast_to_conversation(conversation_id, payload_to_broadcast)

        except WebSocketDisconnect:
            manager.disconnect(conversation_id, websocket)

    except Exception:
        manager.disconnect(conversation_id, websocket)

