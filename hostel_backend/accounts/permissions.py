from rest_framework.permissions import BasePermission


def _has_role(request, role):
    return bool(
        request.user
        and request.user.is_authenticated
        and request.user.role == role
    )


class IsSuperAdmin(BasePermission):
    def has_permission(self, request, view):
        return _has_role(request, 'admin')


class IsWarden(BasePermission):
    def has_permission(self, request, view):
        return _has_role(request, 'warden')


class IsGuard(BasePermission):
    def has_permission(self, request, view):
        return _has_role(request, 'guard')


class IsStudent(BasePermission):
    def has_permission(self, request, view):
        return _has_role(request, 'student')


class IsSuperAdminOrWarden(BasePermission):
    def has_permission(self, request, view):
        return bool(
            request.user
            and request.user.is_authenticated
            and request.user.role in ('admin', 'warden')
        )
