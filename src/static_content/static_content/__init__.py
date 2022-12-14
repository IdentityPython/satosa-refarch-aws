import logging

import satosa.logging_util as lu
import satosa.frontends.base
from satosa.response import Response


logger = logging.getLogger(__name__)


class StaticContentFrontend(satosa.frontends.base.FrontendModule):
    """
    A simple file server for SATOSA
    """

    def __init__(self, auth_req_callback_func, internal_attributes, config, base_url, name):
        super().__init__(auth_req_callback_func, internal_attributes, base_url, name)
        self.config = config

    def handle_authn_response(self, context, internal_resp, extra_id_token_claims=None):
        """
        See super class method satosa.frontends.base.FrontendModule#handle_authn_response
        :type context: satosa.context.Context
        :type internal_response: satosa.internal.InternalData
        :rtype oic.utils.http_util.Response
        """
        raise NotImplementedError()

    def handle_backend_error(self, exception):
        """
        See super class satosa.frontends.base.FrontendModule
        :type exception: satosa.exception.SATOSAError
        :rtype: oic.utils.http_util.Response
        """
        raise NotImplementedError()

    def register_endpoints(self, backend_names):
        """
        See super class satosa.frontends.base.FrontendModule
        :type backend_names: list[str]
        :rtype: list[(str, ((satosa.context.Context, Any) -> satosa.response.Response, Any))]
        :raise ValueError: if more than one backend is configured
        """
        url_map = [("^{}".format(self.name), self.static_content_endpoint)]
        return url_map

    def static_content_endpoint(self, context):
        """
        """
        msg = f"Static content returning {self.config['file']}"
        logline = lu.LOG_FMT.format(id=lu.get_session_id(context.state), message=msg)
        logger.debug(logline)
        file = open(self.config['file'], 'r')
        msg = file.read()
        return Response(msg)
