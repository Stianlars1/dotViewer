# Sample Python file for E2E testing
from dataclasses import dataclass
from typing import Optional, List
import asyncio

@dataclass
class User:
    id: int
    name: str
    email: str

class UserService:
    def __init__(self):
        self._users: List[User] = []

    async def add_user(self, user: User) -> None:
        self._users.append(user)

    def find_user(self, user_id: int) -> Optional[User]:
        for user in self._users:
            if user.id == user_id:
                return user
        return None

if __name__ == "__main__":
    service = UserService()
    asyncio.run(service.add_user(User(1, "Test", "test@example.com")))
