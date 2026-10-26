from rest_framework import serializers
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer


class CustomTokenObtainPairSerializer(TokenObtainPairSerializer):
    """
    Same login endpoint for every role. The response carries `role` and
    `must_change_password` so the Flutter app knows which dashboard —
    or the forced password-change screen — to open next.
    """

    @classmethod
    def get_token(cls, user):
        token = super().get_token(user)
        token['role'] = user.role
        token['must_change_password'] = user.must_change_password
        return token

    def validate(self, attrs):
        data = super().validate(attrs)
        data['role'] = self.user.role
        data['must_change_password'] = self.user.must_change_password
        data['username'] = self.user.username
        data['user_id'] = self.user.id
        return data


class ChangePasswordSerializer(serializers.Serializer):
    new_username = serializers.CharField(required=False, allow_blank=True)
    new_password = serializers.CharField(write_only=True, min_length=8)
    confirm_password = serializers.CharField(write_only=True, min_length=8)

    def validate(self, attrs):
        if attrs['new_password'] != attrs['confirm_password']:
            raise serializers.ValidationError({"confirm_password": "Passwords do not match."})
        return attrs
