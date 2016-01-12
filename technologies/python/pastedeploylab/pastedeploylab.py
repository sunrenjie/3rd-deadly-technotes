import os
import webob.dec
import webob.exc
from webob import Request
from webob import Response
from paste.deploy import loadapp
from wsgiref.simple_server import make_server

"""
A filter class factory shall be defined such that:
0. The factory method shall return the filter class itself. By design, the
   filter does not know the next app, cannot and does not initialize the class
   by itself. The framework performs that. One way to pass instance-specific
   variables to define the filter class internal (see LogFilterV2).
A filter class (returned by the factory) shall be defined such that:
1. The __init__() accepts a single argument app, which is the next app
   (callable class) in the pipeline.
2. The __call__() shall update the arguments environ and start_response, call
   the next app with exactly these same two arguments. To simplify that, use
   @webob.dec.wsgify() instead.

A terminal/app class factory shall be defined such that:
0. The factory method shall initialize and return an instance of the app
   class. The framework does not perform or care about the initialization.
   Thus there is technical no requirement on the __init__() function. This
   also means that we could pass instance variable to the class directly,
   without relying on the internal class hacking.
A terminal/app class shall be defined such that:
0. The __init__() has no requirement, as said above. We are free to pass in
   instance-specific variables we like.
1. The __call__() shall call start_response to set HTTP headers, return the
   final result.

The decorator @webob.dec.wsgify() can help simplify the __call__().

Originally, we would have to write:

    def __call__(self, environ, start_response):
        req = Request(environ)
        res = Response()
        ...
        return res(environ, start_response)

Now we could write instead:

    @webob.dec.wsgify()
    def __call__(self, req):  # request-taking and response-returning
        res = Response()
        ...
        return res  # for terminal/app class
        req.get_response(self.app)  # for filter class

"""


class LogFilter(object):
    def __init__(self, app):
        self.app = app
        pass

    def __call__(self, environ, start_response):
        print "filter:LogFilter is called."
        return self.app(environ, start_response)

    @classmethod
    def factory(cls, global_conf, **kwargs):
        print "in LogFilter.factory", global_conf, kwargs
        return LogFilter


class LogFilterV2(object):
    @classmethod
    def factory(cls, global_conf, **kwargs):
        print "in LogFilter.factory", global_conf, kwargs
        username = kwargs['username']
        password = kwargs['password']

        class Filter(object):
            def __init__(self, app):
                self.app = app
                # pass in arguments in the config file
                self.username = username
                self.password = password

            @webob.dec.wsgify()
            def __call__(self, req):
                print "filter:LogFilterV2 called (username=%s, password=%s)" % (
                    self.username, self.password)
                return req.get_response(self.app)
        return Filter


class ShowVersion(object):

    def __init__(self, version):
        self.version = version
        pass

    def __call__(self, environ, start_response):
        start_response("200 OK", [("Content-type", "text/plain")])
        return "Paste Deploy LAB: Version = %s" % self.version

    @classmethod
    def factory(cls, global_conf, **kwargs):
        print "in ShowVersion.factory", global_conf, kwargs
        # create app class instance with arguments from config file
        return ShowVersion(kwargs['version'])


class Calculator(object):
    def __init__(self):
        pass

    @webob.dec.wsgify()
    def __call__(self, req):
        res = Response()
        res.status = "200 OK"
        res.content_type = "text/plain"
        # get operands
        operator = req.GET.get("operator", None)
        operand1 = req.GET.get("operand1", None)
        operand2 = req.GET.get("operand2", None)
        print req.GET
        opnd1 = int(operand1)
        opnd2 = int(operand2)
        if operator == u'plus':
            result = opnd1 + opnd2
        elif operator == u'minus':
            result = opnd1 - opnd2
        elif operator == u'star':
            result = opnd1 * opnd2
        elif operator == u'slash':
            result = opnd1 / opnd2
        else:
            raise webob.exc.HTTPBadRequest(
                "the operator %s unknown" % operator)
        res.body = "%s /nRESULT= %d" % (str(req.GET), result)
        return res

    @classmethod
    def factory(cls, global_conf, **kwargs):
        print "in Calculator.factory", global_conf, kwargs
        return Calculator()


if __name__ == '__main__':
    configfile = "pastedeploylab.ini"
    appname = "pdl"
    wsgi_app = loadapp("config:%s" % os.path.abspath(configfile), appname)
    server = make_server('localhost', 8080, wsgi_app)
    usages = """
    Usages: access these URLs using curl or httpie:
        http://127.0.0.1:8080/
        http://127.0.0.1:8080/calc?operator=plus&operand1=12&operand2=23
        http://127.0.0.1:8080/admin/users/
        http://127.0.0.1:8080/admin/users/1

    Note: our URL routing/mapping here is naive, if /admin (no terminal '/')
    is requested, the server will throw exception
    'RoutesException: URL or environ must be provided'.
    """
    print(usages)
    server.serve_forever()
