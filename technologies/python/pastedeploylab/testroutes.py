import logging
import os

import webob
import webob.dec
import webob.exc
from paste.deploy import loadapp
from wsgiref.simple_server import make_server

import routes
import routes.middleware

# Environment variable used to pass the request context
CONTEXT_ENV = 'openstack.context'

# Environment variable used to pass the request params
PARAMS_ENV = 'openstack.params'

LOG = logging.getLogger(__name__)


class Controller(object):
    @webob.dec.wsgify
    def __call__(self, req):
        arg_dict = req.environ['wsgiorg.routing_args'][1]
        action = arg_dict.pop('action')
        del arg_dict['controller']
        context = req.environ.get(CONTEXT_ENV, {})
        context['query_string'] = dict(req.params.iteritems())
        context['headers'] = dict(req.headers.iteritems())
        context['path'] = req.environ['PATH_INFO']
        params = req.environ.get(PARAMS_ENV, {})

        for name in ['REMOTE_USER', 'AUTH_TYPE']:
            try:
                context[name] = req.environ[name]
            except KeyError:
                try:
                    del context[name]
                except KeyError:
                    pass

        params.update(arg_dict)

        # TODO(termie): do some basic normalization on methods
        method = getattr(self, action)

        result = method(context, **params)

        return webob.Response(result)

    @staticmethod
    def get_user_by_id(context, user_id):
        return 'the user %s is on leave' % user_id

    @staticmethod
    def get_users(context):
        return 'the user list is in db'


class Router(object):
    def __init__(self):
        self._mapper = routes.Mapper()
        self._mapper.connect('/users/{user_id}',
                             controller=Controller(),
                             action='get_user_by_id',
                             conditions={'method': ['GET']})
        self._mapper.connect('/users/',
                             controller=Controller(),
                             action='get_users',
                             conditions={'method': ['GET']})

        self._router = routes.middleware.RoutesMiddleware(self._dispatch, self._mapper)

    @webob.dec.wsgify
    def __call__(self, req):
        return self._router

    @staticmethod
    @webob.dec.wsgify
    def _dispatch(req):
        match = req.environ['wsgiorg.routing_args'][1]

        if not match:
            return webob.exc.HTTPNotFound()

        app = match['controller']
        return app

    @classmethod
    def app_factory(cls, global_config, **local_config):
        return cls()


if __name__ == '__main__':
    configfile = 'testroutes.ini'
    appname = "main"
    wsgi_app = loadapp("config:%s" % os.path.abspath(configfile), appname)
    usages = """
    Usages: access these URLs using curl or httpie:
        http://127.0.0.1:8082/users/
        http://127.0.0.1:8082/users/1
    """
    print(usages)
    httpd = make_server('localhost', 8282, wsgi_app)
    httpd.serve_forever()
