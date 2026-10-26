from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin

from .models import User


class UserAdmin(BaseUserAdmin):
    list_display = ('username', 'role', 'is_active', 'must_change_password')
    fieldsets = BaseUserAdmin.fieldsets + (
        ('Role info', {'fields': ('role', 'must_change_password')}),
    )


admin.site.register(User, UserAdmin)
