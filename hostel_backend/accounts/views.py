from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.views import TokenObtainPairView

from .serializers import ChangePasswordSerializer, CustomTokenObtainPairSerializer


class LoginView(TokenObtainPairView):
    """POST username + password -> access/refresh tokens + role + must_change_password."""
    serializer_class = CustomTokenObtainPairSerializer


class ChangePasswordView(APIView):
    """
    Used both for the forced first-login password change and for a normal
    'change my password' action from any dashboard.
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):
        serializer = ChangePasswordSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        user = request.user
        new_username = serializer.validated_data.get('new_username')
        if new_username:
            user.username = new_username

        user.set_password(serializer.validated_data['new_password'])
        user.must_change_password = False
        user.save()

        return Response({"detail": "Password updated successfully."}, status=status.HTTP_200_OK)
