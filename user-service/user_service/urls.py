from django.urls import path
from django.http import JsonResponse

def health(request):
    return JsonResponse({"status": "ok", "service": "user-service"})

def index(request):
    return JsonResponse({"service": "user-service", "message": "Starter API; implement CandyStore business logic here"})

urlpatterns = [path("health/", health), path("", index)]
