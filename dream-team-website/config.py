# config.py

class Config(object):
    """
    Common configurations
    """

    # Put any configurations here that are common across all environments
    TESTING = False
    DEBUG = True

class DevelopmentConfig(Config):
    """
    Development configurations
    More Flask: http://flask.pocoo.org/docs/0.11/config/
    More SqlAlchemy: http://flask-sqlalchemy.pocoo.org/2.1/config/
    """
    SQLALCHEMY_ECHO = True

class ProductionConfig(Config):
    """
    Production configurations
    """

    DEBUG = False

class TestingConfig(Config):
    """
    Testing configurations
    """

    TESTING = True

app_config = {
    'development': DevelopmentConfig,
    'production': ProductionConfig,
    'testing': TestingConfig
    }