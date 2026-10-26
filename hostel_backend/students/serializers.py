from django.contrib.auth import get_user_model
from rest_framework import serializers

from .models import Student

User = get_user_model()


class StudentSerializer(serializers.ModelSerializer):
    username = serializers.CharField(write_only=True)
    password = serializers.CharField(write_only=True, min_length=6)
    full_name = serializers.CharField(write_only=True)

    student_name = serializers.CharField(source='user.get_full_name', read_only=True)
    student_username = serializers.CharField(source='user.username', read_only=True)
    hostel_name = serializers.CharField(source='hostel.name', read_only=True)
    login_active = serializers.BooleanField(source='user.must_change_password', read_only=True)

    class Meta:
        model = Student
        fields = [
            'id', 'username', 'password', 'full_name',
            'student_name', 'student_username', 'hostel', 'hostel_name', 'login_active',
            'enrollment_no', 'room_no', 'phone', 'parent_contact',
        ]
        # hostel is set by the view (from the warden's own hostel), never from the client
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
            role=User.Role.STUDENT,
            must_change_password=True,
        )
        return Student.objects.create(user=user, **validated_data)
