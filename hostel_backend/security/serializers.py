from django.contrib.auth import get_user_model
from rest_framework import serializers

from .models import SecurityGuard

User = get_user_model()


class SecurityGuardSerializer(serializers.ModelSerializer):
    username = serializers.CharField(write_only=True)
    password = serializers.CharField(write_only=True, min_length=6)
    full_name = serializers.CharField(write_only=True)

    guard_name = serializers.CharField(source='user.get_full_name', read_only=True)
    guard_username = serializers.CharField(source='user.username', read_only=True)
    hostel_name = serializers.CharField(source='hostel.name', read_only=True)
    login_active = serializers.BooleanField(source='user.must_change_password', read_only=True)

    class Meta:
        model = SecurityGuard
        fields = [
            'id', 'username', 'password', 'full_name',
            'guard_name', 'guard_username', 'hostel', 'hostel_name', 'login_active',
            'shift_time',
        ]
        read_only_fields = ['hostel']

    def validate_username(self, value):
        if User.objects.filter(username=value).exists():
            raise serializers.ValidationError("That username is already taken.")
        return value

    def create(self, validated_data):
        username = validated_data.pop('username')
        password = validated_data.pop('password')
        full_name = validated_data.pop('full_name')

        user = User.objects.create_user(
            username=username,
            password=password,
            first_name=full_name,
            role=User.Role.GUARD,
            must_change_password=True,
        )
        return SecurityGuard.objects.create(user=user, **validated_data)
