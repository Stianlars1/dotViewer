// Sample Rust file for E2E testing
use std::collections::HashMap;

#[derive(Debug, Clone)]
struct User {
    id: u32,
    name: String,
    email: String,
}

struct UserRepository {
    users: HashMap<u32, User>,
}

impl UserRepository {
    fn new() -> Self {
        UserRepository {
            users: HashMap::new(),
        }
    }

    fn add(&mut self, user: User) {
        self.users.insert(user.id, user);
    }

    fn find(&self, id: u32) -> Option<&User> {
        self.users.get(&id)
    }
}

fn main() {
    let mut repo = UserRepository::new();
    repo.add(User {
        id: 1,
        name: String::from("Test"),
        email: String::from("test@example.com"),
    });
    println!("User added: {:?}", repo.find(1));
}
