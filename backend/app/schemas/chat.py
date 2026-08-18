from datetime import datetime
from typing import List, Optional
from pydantic import BaseModel, ConfigDict
from app.schemas.user import UserResponse

# Message Schemas
class ChatMessageBase(BaseModel):
    content: str

class ChatMessageCreate(ChatMessageBase):
    pass

class ChatMessageResponse(ChatMessageBase):
    id: int
    conversation_id: int
    sender_id: int
    sender: UserResponse
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


# Participant Schema
class ConversationParticipantResponse(BaseModel):
    id: int
    user_id: int
    user: UserResponse
    joined_at: datetime
    last_read_at: Optional[datetime] = None

    model_config = ConfigDict(from_attributes=True)


# Conversation Schemas
class ConversationResponse(BaseModel):
    id: int
    is_group: bool
    title: Optional[str] = None
    created_at: datetime
    updated_at: datetime
    participants: List[ConversationParticipantResponse]
    last_message: Optional[ChatMessageResponse] = None
    unread_count: int = 0

    model_config = ConfigDict(from_attributes=True)


class DirectConversationCreate(BaseModel):
    target_user_id: int


# User Search Schema
class UserSearchResponse(BaseModel):
    id: int
    username: str
    email: str
    full_name: Optional[str] = None

    model_config = ConfigDict(from_attributes=True)
