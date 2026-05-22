---
name: database-relational-skill
description: >
  Relational database patterns: PostgreSQL, MySQL, SQLAlchemy, migrations, transactions. Trigger:
  "PostgreSQL", "MySQL", "SQL", "database", "SQLAlchemy", "migration", "transaction".
---

## When to Use

- PostgreSQL or MySQL databases
- SQLAlchemy ORM
- Database migrations
- Transaction management
- Query optimization

## SQLAlchemy Setup

```python
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base

DATABASE_URL = "postgresql://user:pass@localhost:5432/mydb"

engine = create_engine(DATABASE_URL, pool_pre_ping=True)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
```

## Models

```python
from sqlalchemy import Column, Integer, String, ForeignKey, DateTime, Boolean
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String(255), unique=True, index=True, nullable=False)
    username = Column(String(100), unique=True, index=True)
    hashed_password = Column(String(255), nullable=False)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    posts = relationship("Post", back_populates="author")

    def __repr__(self):
        return f"<User {self.username}>"

class Post(Base):
    __tablename__ = "posts"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String(255), nullable=False)
    content = Column(String, nullable=False)
    author_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    published = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    author = relationship("User", back_populates="posts")
    tags = relationship("Tag", secondary=post_tags, back_populates="posts")
```

## Migrations

```bash
# Create migration
alembic revision --autogenerate -m "Add posts table"

# Apply migrations
alembic upgrade head

# Rollback
alembic downgrade -1

# Check current
alembic current

# History
alembic history
```

## CRUD Operations

```python
def get_user(db: Session, user_id: int):
    return db.query(User).filter(User.id == user_id).first()

def get_user_by_email(db: Session, email: str):
    return db.query(User).filter(User.email == email).first()

def create_user(db: Session, user: UserCreate):
    hashed_password = hash_password(user.password)
    db_user = User(
        email=user.email,
        username=user.username,
        hashed_password=hashed_password
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user

def update_user(db: Session, user_id: int, user_update: UserUpdate):
    db_user = get_user(db, user_id)
    if not db_user:
        return None
    for key, value in user_update.dict(exclude_unset=True).items():
        setattr(db_user, key, value)
    db.commit()
    db.refresh(db_user)
    return db_user

def delete_user(db: Session, user_id: int):
    db_user = get_user(db, user_id)
    if db_user:
        db.delete(db_user)
        db.commit()
        return True
    return False
```

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
```

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



## References

See [references/](references/) for detailed examples:

- [Example 1](references/code-example-1.md)
- [Example 2](references/code-example-2.md)


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

