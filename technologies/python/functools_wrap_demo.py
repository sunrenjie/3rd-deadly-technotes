# Demo of the functools.wrap annotation. Copied out from standard lib code of
# python 3 (version: 3.4.3) such that it runs without imports.

# Purely functional, no descriptor behaviour
def partial(func, *args, **keywords):
    """New function with partial application of the given arguments
    and keywords.
    """

    def newfunc(*fargs, **fkeywords):
        print('newfunc')
        newkeywords = keywords.copy()
        newkeywords.update(fkeywords)
        return func(*(args + fargs), **newkeywords)

    print('partial')
    newfunc.func = func
    newfunc.args = args
    newfunc.keywords = keywords
    return newfunc


WRAPPER_ASSIGNMENTS = ('__module__', '__name__', '__qualname__', '__doc__',
                       '__annotations__')
WRAPPER_UPDATES = ('__dict__',)


def update_wrapper(wrapper,
                   wrapped,
                   assigned=WRAPPER_ASSIGNMENTS,
                   updated=WRAPPER_UPDATES):
    """Update a wrapper function to look like the wrapped function

       wrapper is the function to be updated
       wrapped is the original function
       assigned is a tuple naming the attributes assigned directly
       from the wrapped function to the wrapper function (defaults to
       functools.WRAPPER_ASSIGNMENTS)
       updated is a tuple naming the attributes of the wrapper that
       are updated with the corresponding attribute from the wrapped
       function (defaults to functools.WRAPPER_UPDATES)
    """
    print('update_wrapper')
    for attr in assigned:
        try:
            value = getattr(wrapped, attr)
        except AttributeError:
            pass
        else:
            setattr(wrapper, attr, value)
    for attr in updated:
        getattr(wrapper, attr).update(getattr(wrapped, attr, {}))
    # Issue #17482: set __wrapped__ last so we don't inadvertently copy it
    # from the wrapped function when updating __dict__
    wrapper.__wrapped__ = wrapped
    # Return the wrapper so this can be used as a decorator via partial()
    return wrapper


def wraps(wrapped,
          assigned=WRAPPER_ASSIGNMENTS,
          updated=WRAPPER_UPDATES):
    """Decorator factory to apply update_wrapper() to a wrapper function

       Returns a decorator that invokes update_wrapper() with the decorated
       function as the wrapper argument and the arguments to wraps() as the
       remaining arguments. Default arguments are as for update_wrapper().
       This is a convenience function to simplify applying partial() to
       update_wrapper().
    """
    print('wraps')
    return partial(update_wrapper, wrapped=wrapped,
                   assigned=assigned, updated=updated)


def flow_start_view(view):
    """
    Decorator for start views, creates and initializes start activation

    Expects view with the signature `(request, **kwargs)`
    Returns view with the signature `(request, flow_class, flow_task, **kwargs)`
    """

    @wraps(view)
    def _wrapper(request, flow_class, flow_task, **kwargs):
        print('_wrapper@flow_start_view')
        try:
            activation = flow_task.activation_class()
            activation.initialize(flow_task, None)

            request.activation = activation
            request.process = activation.process
            request.task = activation.task
            return view(request, **kwargs)
        finally:
            if activation.lock:
                activation.lock.__exit__(*sys.exc_info())

    print('flow_start_view')
    return _wrapper


@flow_start_view
def start_view(request):
    print('start_view')

