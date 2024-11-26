SITENAME = 'blog/mzan'
SITEURL = ''

PATH = 'content'
STATIC_PATHS = ['images']

TIMEZONE = 'Europe/Rome'

DEFAULT_LANG = 'en'

# Feed generation is usually not desired when developing
FEED_ALL_ATOM = None
CATEGORY_FEED_ATOM = None
TRANSLATION_FEED_ATOM = None
AUTHOR_FEED_ATOM = None
AUTHOR_FEED_RSS = None

# Blogroll
LINKS = (('dokmelody/bootstrapping', 'https://bootstrapping.dokmelody.org/'),
         ('GitHub', 'https://github.com/massimo-zaniboni'),)

# Social widget
SOCIAL = (('@mzan@qoto.org', 'https://qoto.org/@mzan'),
          ('mzan@dokmelody.org', 'mailto: mzan@dokmelody.org'),)
# TODO    ('@dokmelody@fosstodon.org', 'https://fosstodon.org/@dokmelody'),)

DEFAULT_PAGINATION = 25

# Uncomment following line if you want document-relative URLs when developing
#RELATIVE_URLS = True

THEME = 'themes/notmyidea-custom'
