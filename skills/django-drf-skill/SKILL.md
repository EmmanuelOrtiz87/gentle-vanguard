---
name: django-drf-skill
description: >
  Django REST Framework patterns: ViewSets, Serializers, Filters, Permissions. Trigger: "Django",
  "Django REST Framework", "DRF", "ViewSet", "Serializer", "APIView".
metadata:
  source: GV-native
---

## When to Use

- Building REST APIs with Django
- Django REST Framework implementation
- API serializers and validation
- ViewSets and routers

## Project Structure

```
project/
 manage.py
 project/
    settings.py
    urls.py
    wsgi.py
 apps/
     users/
         models.py
         serializers.py
         views.py
         urls.py
         filters.py
```

## Serializers

```python
from rest_framework import serializers
from django.contrib.auth.models import User

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'first_name', 'last_name']
        read_only_fields = ['id']

class UserDetailSerializer(UserSerializer):
    groups = serializers.StringRelatedField(many=True)

    class Meta(UserSerializer.Meta):
        fields = UserSerializer.Meta.fields + ['groups', 'date_joined']
```

## Nested Serializers

```python
class CommentSerializer(serializers.ModelSerializer):
    author = UserSerializer(read_only=True)
    author_id = serializers.PrimaryKeyRelatedField(
        queryset=User.objects.all(),
        source='author',
        write_only=True
    )

    class Meta:
        model = Comment
        fields = ['id', 'content', 'author', 'author_id', 'created_at']
        read_only_fields = ['id', 'created_at']
```

## ViewSets

```python
from rest_framework import viewsets, permissions
from django.contrib.auth.models import User
from .serializers import UserSerializer

class UserViewSet(viewsets.ModelViewSet):
    """
    API endpoint for users.
    """
    queryset = User.objects.all().order_by('-date_joined')
    serializer_class = UserSerializer
    permission_classes = [permissions.IsAuthenticated]
    filterset_fields = ['username', 'email', 'is_active']
    search_fields = ['username', 'email']
    ordering_fields = ['username', 'date_joined']
    ordering = ['-date_joined']
```

## Custom Actions

```python
class UserViewSet(viewsets.ModelViewSet):
    queryset = User.objects.all()
    serializer_class = UserSerializer

    @action(detail=True, methods=['post'])
    def set_password(self, request, pk=None):
        user = self.get_object()
        serializer = PasswordSerializer(data=request.data)
        if serializer.is_valid():
            user.set_password(serializer.validated_data['password'])
            user.save()
            return Response({'status': 'password set'})
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    @action(detail=False, methods=['get'])

---

> **Referencia detallada**: [
eferences/detail.md](references/detail.md)
```
