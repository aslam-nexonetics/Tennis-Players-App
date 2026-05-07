import sys
import os
import asyncio
from playwright.async_api import async_playwright

async def dump_profile():
    async with async_playwright() as p:
        browser = await p.chromium.launch()
        page = await browser.new_page()
        url = "https://www.atptour.com/en/players/jannik-sinner/s0au/overview"
        print(f"Loading {url}...")
        await page.goto(url)
        content = await page.content()
        # Look for name
        if "Jannik" in content:
            print("Found 'Jannik' in content")
        
        # Try selectors
        name_div = await page.query_selector(".atp_player-profile-hero-name")
        if name_div:
            print(f"Found .atp_player-profile-hero-name: {await name_div.inner_text()}")
        else:
            print("Could not find .atp_player-profile-hero-name")
            # Try other common ones
            name_h1 = await page.query_selector("h1")
            if name_h1:
                print(f"H1: {await name_h1.inner_text()}")
        
        await browser.close()

if __name__ == "__main__":
    asyncio.run(dump_profile())
