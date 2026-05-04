---
name: django-drf-skill
description: >
  Django REST Framework patterns: ViewSets, Serializers, Filters, Permissions.
  Trigger: "Django", "Django REST Framework", "DRF", "ViewSet", "Serializer", "APIView".
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
    def recent(self, request):
        recent_users = User.objects.order_by('-date_joined')[:10]
        serializer = self.get_serializer(recent_users, many=True)
        return Response(serializer.data)
```

## Permissions

```python
from rest_framework import permissions

class IsOwnerOrReadOnly(permissions.BasePermission):
    def has_object_permission(self, request, view, obj):
        if request.method in permissions.SAFE_METHODS:
            return True
        return obj.owner == request.user

class IsAdminUser(permissions.BasePermission):
    def has_permission(self, request, view):
        return request.user and request.user.is_staff
```

## Filters

```python
# filters.py
from rest_framework import filters

class UserFilter(filters.FilterSet):
    username = filters.CharFilter(lookup_expr='icontains')
    is_active = filters.BooleanFilter()
    created_after = filters.DateTimeFilter(field_name='date_joined', lookup_expr='gte')
    
    class Meta:
        model = User
        fields = ['username', 'is_active', 'created_after']
```

## URLs

```python
# app/urls.py
from rest_framework.routers import DefaultRouter
from .views import UserViewSet

router = DefaultRouter()
router.register(r'users', UserViewSet)

urlpatterns = [
    path('', include(router.urls)),
]
```

## Pagination

```python
# settings.py
REST_FRAMEWORK = {
    'DEFAULT_PAGINATION_CLASS': 'rest_framework.pagination.PageNumberPagination',
    'PAGE_SIZE': 20,
    'DEFAULT_FILTER_BACKENDS': [
        'django_filters.rest_framework.DjangoFilterBackend',
        'rest_framework.filters.SearchFilter',
        'rest_framework.filters.OrderingFilter',
    ],
}
```

## Authentication

```python
# settings.py
REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': [
        'rest_framework.authentication.SessionAuthentication',
        'rest_framework.authentication.TokenAuthentication',
        'rest_framework.authentication.BasicAuthentication',
    ],
    'DEFAULT_PERMISSION_CLASSES': [
        'rest_framework.permissions.IsAuthenticated',
    ],
}
```

## Exception Handling

```python
from rest_framework.views import exception_handler
from rest_framework.response import Response

def custom_exception_handler(exc, context):
    response = exception_handler(exc, context)
    
    if response is not None:
        response.data['status_code'] = response.status_code
        
    return response
```

## Quick Reference

| Component | Purpose |
|-----------|---------|
| ModelSerializer | Auto-generate from model |
| ViewSet | CRUD operations |
| Router | URL generation |
| FilterSet | Query filtering |
| Permission | Access control |
| Pagination | Response pagination |

