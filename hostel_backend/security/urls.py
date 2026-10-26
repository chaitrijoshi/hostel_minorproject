from rest_framework.routers import DefaultRouter

from .views import SecurityGuardViewSet

router = DefaultRouter()
router.register('', SecurityGuardViewSet, basename='guard')

urlpatterns = router.urls
