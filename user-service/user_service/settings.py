from pathlib import Path
BASE_DIR = Path(__file__).resolve().parent.parent
SECRET_KEY = "development-only-change-me"
DEBUG = False
ALLOWED_HOSTS = ["*"]
ROOT_URLCONF = "user_service.urls"
INSTALLED_APPS = ["django.contrib.contenttypes", "django.contrib.staticfiles"]
MIDDLEWARE = ["django.middleware.security.SecurityMiddleware", "django.middleware.common.CommonMiddleware"]
TEMPLATES = []
WSGI_APPLICATION = "user_service.wsgi.application"
DATABASES = {"default": {"ENGINE": "django.db.backends.sqlite3", "NAME": BASE_DIR / "db.sqlite3"}}
STATIC_URL = "static/"
DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"
