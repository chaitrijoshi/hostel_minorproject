from rest_framework.routers import DefaultRouter

from .views import WardenViewSet

router = DefaultRouter()
router.register('', WardenViewSet, basename='warden')

urlpatterns = router.urls
