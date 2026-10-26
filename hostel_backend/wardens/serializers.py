from django.contrib.auth import get_user_model
from rest_framework import serializers

from hostels.models import Hostel

from .models import Warden

User = get_user_model()


class WardenSerializer(serializers.ModelSerializer):
    # write-only: used only when creating a brand new warden login
    username = serializers.CharField(write_only=True)
    password = serializers.CharField(write_only=True, min_length=6)
    full_name = serializers.CharField(write_only=True)
    hostel_id = serializers.PrimaryKeyRelatedField(
        queryset=Hostel.objects.all(), source='hostel', write_only=True
    )

    # read-only convenience fields for the admin's table view
    warden_name = serializers.CharField(source='user.get_full_name', read_only=True)
    warden_username = serializers.CharField(source='user.username', read_only=True)
    hostel_name = serializers.CharField(source='hostel.name', read_only=True)
    login_active = serializers.BooleanField(source='user.must_change_password', read_only=True)

    class Meta:
        model = Warden
        fields = [
            'id', 'username', 'password', 'full_name', 'hostel_id',
            'warden_name', 'warden_username', 'hostel_name', 'login_active',
            'assigned_date',
        ]

    def validate_username(self, value):
        if User.objects.filter(username=value).exists():
            raise serializers.ValidationError("That username is already taken.")
        return value

    def create(self, validated_data):
        username = validated_data.pop('username')
        password = validated_data.pop('password')
        full_name = validated_data.pop('full_name')
        hostel = validated_data.pop('hostel')

        user = User.objects.create_user(
            username=username,
            password=password,
            first_name=full_name,
            role=User.Role.WARDEN,
            must_change_password=True,
        )
        return Warden.objects.create(user=user, hostel=hostel)
