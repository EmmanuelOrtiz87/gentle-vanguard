    def recent(self, request):
        recent_users = User.objects.order_by('-date_joined')[:10]
        serializer = self.get_serializer(recent_users, many=True)
        return Response(serializer.data)

````

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
````

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

| Component       | Purpose                  |
| --------------- | ------------------------ |
| ModelSerializer | Auto-generate from model |
| ViewSet         | CRUD operations          |
| Router          | URL generation           |
| FilterSet       | Query filtering          |
| Permission      | Access control           |
| Pagination      | Response pagination      |
