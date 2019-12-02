
#include <grpc/grpc.h>
#include <grpcpp/grpcpp.h>

#include <opencv2/core.hpp>
#include <opencv2/videoio/videoio.hpp>

#include <main.grpc.pb.h>


class main_service final : public dminer::Greeter::Service {
	grpc::Status SayHello(grpc::ServerContext* context, const dminer::HelloRequest* request,
		dminer::HelloReply* reply) override {
		std::string prefix("Hello ");
		reply->set_message(prefix + request->name());
		return grpc::Status::OK;
	}
};

void RunServer() {
	std::string server_address("[::1]:8451");
	main_service service;

	grpc::ServerBuilder builder;
	// Listen on the given address without any authentication mechanism.
	builder.AddListeningPort(server_address, grpc::InsecureServerCredentials());
	// Register "service" as the instance through which we'll communicate with
	// clients. In this case it corresponds to an *synchronous* service.
	builder.RegisterService(&service);
	// Finally assemble the server.
	std::unique_ptr<grpc::Server> server(builder.BuildAndStart());
	std::cout << "Server listening on " << server_address << std::endl;

	// Wait for the server to shutdown. Note that some other thread must be
	// responsible for shutting down the server for this call to ever return.
	server->Wait();
}

int main()
{
	RunServer();
	/*cv::VideoCapture cp;
	if (!cp.isOpened())
		return -1;*/
	return 0;
}