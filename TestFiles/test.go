// Sample Go file for E2E testing
package main

import (
    "fmt"
    "sync"
)

type User struct {
    ID    int    `json:"id"`
    Name  string `json:"name"`
    Email string `json:"email"`
}

type UserStore struct {
    mu    sync.RWMutex
    users map[int]*User
}

func NewUserStore() *UserStore {
    return &UserStore{
        users: make(map[int]*User),
    }
}

func (s *UserStore) Add(user *User) {
    s.mu.Lock()
    defer s.mu.Unlock()
    s.users[user.ID] = user
}

func main() {
    store := NewUserStore()
    store.Add(&User{ID: 1, Name: "Test", Email: "test@example.com"})
    fmt.Println("User added successfully")
}
