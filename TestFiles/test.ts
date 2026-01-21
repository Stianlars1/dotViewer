// Sample TypeScript file for E2E testing
interface User {
    id: number;
    name: string;
    email: string;
}

type UserRole = 'admin' | 'user' | 'guest';

class UserRepository {
    private users: Map<number, User> = new Map();

    async create(user: User): Promise<User> {
        this.users.set(user.id, user);
        return user;
    }

    async findById(id: number): Promise<User | undefined> {
        return this.users.get(id);
    }

    async delete(id: number): Promise<boolean> {
        return this.users.delete(id);
    }
}

export { User, UserRole, UserRepository };
