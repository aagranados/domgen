#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

module Domgen
  module JWS
    class JwsClass < Domgen.ParentedElement(:service)

      def boundary_ejb_name
        "#{service.data_module.repository.name}.#{service.data_module.name}.#{service.jws.java_service_name}"
      end

      attr_writer :url

      def url
        @url || "#{service.data_module.jws.url}/#{web_service_name}"
      end

      attr_writer :port_type_name

      def port_type_name
        @port_type_name || web_service_name
      end

      attr_writer :port_name

      def port_name
        @port_name || "#{web_service_name}Port"
      end

      attr_writer :web_service_name

      def web_service_name
        @web_service_name || service.name.to_s
      end

      attr_writer :wsdl_name

      def wsdl_name
        @wsdl_name || "#{service.data_module.repository.name}/#{service.data_module.name}/#{web_service_name}.wsdl"
      end

      attr_writer :system_id

      def system_id
        @system_id || "#{namespace}.wsdl"
      end

      def namespace
        @namespace || "#{service.data_module.jws.namespace}/#{web_service_name}"
      end

      attr_writer :service_name

      def service_name
        @service_name || "#{service.name}Service"
      end

      def qualified_service_name
        "#{service.data_module.jws.service_package}.#{service_name}"
      end

      def java_service_name
        "#{web_service_name}WS"
      end

      def qualified_java_service_name
        "#{service.data_module.jws.service_package}.#{java_service_name}"
      end

      def boundary_implementation_name
        "#{web_service_name}WSBoundaryEJB"
      end

      def qualified_boundary_implementation_name
        "#{service.data_module.jws.service_package}.#{boundary_implementation_name}"
      end

      def fake_implementation_name
        "Fake#{web_service_name}"
      end

      def qualified_fake_implementation_name
        "#{service.data_module.jws.fake_service_package}.#{fake_implementation_name}"
      end
    end

    class JwsParameter < Domgen.ParentedElement(:parameter)
      def name
        Domgen::Naming.camelize(parameter.name)
      end

      include Domgen::Java::EEJavaCharacteristic

      protected

      def characteristic
        parameter
      end
    end

    class JwsMethod < Domgen.ParentedElement(:method)
      def name
        Domgen::Naming.camelize(method.name)
      end

      def input_action
        "#{method.service.jws.namespace}/#{method.service.jws.web_service_name}/#{method.name}Request"
      end

      def output_action
        "#{method.service.jws.namespace}/#{method.service.jws.web_service_name}/#{method.name}Response"
      end
    end

    class JwsPackage < Domgen.ParentedElement(:data_module)
      include Domgen::Java::EEJavaPackage

      def namespace
        @namespace || "#{data_module.repository.jws.namespace}/#{data_module.name}"
      end

      attr_writer :fake_service_package

      def fake_service_package
        @fake_service_package || resolve_package(:fake_service_package, data_module.repository.jws)
      end

      attr_writer :url

      def url
        @url || "#{data_module.repository.jws.url}/#{data_module.name}"
      end
    end

    class JwsApplication < Domgen.ParentedElement(:repository)
      attr_writer :fake_service_package

      def fake_service_package
        @fake_service_package || "#{repository.java.base_package}.fake"
      end

      def fake_server_name
        "Fake#{repository.name}Server"
      end

      def qualified_fake_server_name
        "#{fake_service_package}.#{fake_server_name}"
      end

      attr_writer :fake_server_test_name

      def fake_server_test_name
        @fake_server_test_name || "AbstractFake#{repository.name}ServerTest"
      end

      def qualified_fake_server_test_name
        "#{fake_service_package}.#{fake_server_test_name}"
      end

      attr_writer :service_name

      # The name of the service under which web services will be anchored
      def service_name
        @service_name || repository.name
      end

      attr_writer :namespace

      def namespace
        @namespace || "#{repository.xml.base_namespace}/#{service_name}"
      end

      attr_writer :url

      def url
        @url || "/api/soap"
      end
    end

    class JwsReturn < Domgen.ParentedElement(:result)

      include Domgen::Java::EEJavaCharacteristic

      protected

      def characteristic
        result
      end
    end

    class JwsException < Domgen.ParentedElement(:exception)
      def name
        "#{exception.name}_Exception"
      end

      def qualified_name
        "#{exception.data_module.jws.service_package}.#{name}"
      end

      def fault_info_name
        "#{exception.name}ExceptionInfo"
      end

      def qualified_fault_info_name
        "#{exception.data_module.jws.service_package}.#{fault_info_name}"
      end

      attr_writer :namespace

      def namespace
        @namespace || exception.data_module.jws.namespace
      end
    end
  end

  FacetManager.define_facet(:jws,
                            {
                              Service => Domgen::JWS::JwsClass,
                              Method => Domgen::JWS::JwsMethod,
                              Parameter => Domgen::JWS::JwsParameter,
                              Exception => Domgen::JWS::JwsException,
                              Result => Domgen::JWS::JwsReturn,
                              DataModule => Domgen::JWS::JwsPackage,
                              Repository => Domgen::JWS::JwsApplication
                            },
                            [:jaxb])
end
