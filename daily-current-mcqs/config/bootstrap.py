"""
config/bootstrap.py

Import first in CLI entry points to silence known harmless warnings on
system Python 3.9 (EOL notices from google-auth / google.api_core).
"""

import warnings

warnings.filterwarnings(
    "ignore",
    category=FutureWarning,
    module=r"google\.auth",
)
warnings.filterwarnings(
    "ignore",
    category=FutureWarning,
    module=r"google\.oauth2",
)
warnings.filterwarnings(
    "ignore",
    category=FutureWarning,
    module=r"google\.api_core\._python_version_support",
)

warnings.filterwarnings("ignore", module=r"urllib3")
