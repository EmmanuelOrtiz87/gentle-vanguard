        hashed_password=hashed_password
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user

def update_user(db: Session, user_id: int, user_update: UserUpdate): db_user = get_user(db, user_id)
if not db_user: return None for key, value in user_update.dict(exclude_unset=True).items():
setattr(db_user, key, value) db.commit() db.refresh(db_user) return db_user

def delete_user(db: Session, user_id: int): db_user = get_user(db, user_id) if db_user:
db.delete(db_user) db.commit() return True return False

````

## Queries

```python
# Basic queries
users = db.query(User).all()
active_users = db.query(User).filter(User.is_active == True).all()

# Filtering
posts = db.query(Post).filter(
    Post.published == True,
    Post.created_at >= datetime(2024, 1, 1)
).all()

# Search (ilike for case-insensitive)
results = db.query(User).filter(
    User.username.ilike(f"%{search_term}%")
).all()

# Ordering
posts = db.query(Post).order_by(Post.created_at.desc()).all()

# Pagination
page = 1
per_page = 20
posts = db.query(Post).offset((page - 1) * per_page).limit(per_page).all()

# Count
total = db.query(func.count(User.id)).scalar()

# Joins
results = db.query(Post, User).join(User, Post.author_id == User.id).all()
````

## Transactions

```python
def transfer_funds(db: Session, from_id: int, to_id: int, amount: Decimal):
    try:
        from_account = db.query(Account).filter(Account.id == from_id).with_for_update().first()
        to_account = db.query(Account).filter(Account.id == to_id).with_for_update().first()

        if from_account.balance < amount:
            raise ValueError("Insufficient funds")

        from_account.balance -= amount
        to_account.balance += amount

        db.commit()
        return True
    except Exception as e:
        db.rollback()
        raise e
```

## Quick Reference

| Operation   | Code                                      |
| ----------- | ----------------------------------------- |
| Create      | `db.add(obj); db.commit()`                |
| Read        | `db.query(Model).filter(...).first()`     |
| Update      | `obj.attr = val; db.commit()`             |
| Delete      | `db.delete(obj); db.commit()`             |
| Transaction | `try: ... except: db.rollback()`          |
| Join        | `db.query(A, B).join(B, A.b_id == B.id)`  |
| Count       | `db.query(func.count(Model.id)).scalar()` |
