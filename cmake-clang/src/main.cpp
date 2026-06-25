#include <IntelPresentMon/PresentMonAPIWrapper/PresentMonAPIWrapper.h>
#include <IntelPresentMon/PresentMonAPIWrapper/DiagnosticHandler.h>
#include <iostream>
#include <chrono>
#include <thread>
#include <cstdio>

using namespace std::literals;

int main(int argc, const char** argv)
{
	const int targetPid = (argc > 1) ? std::stoi(argv[1]) : 12345;

	try {
		pmapi::Session session;

		const int diagnosticOutputs =
			PM_DIAGNOSTIC_OUTPUT_FLAGS_STDERR | PM_DIAGNOSTIC_OUTPUT_FLAGS_DEBUGGER;
		pmapi::DiagnosticHandler diagnostics{
			PM_DIAGNOSTIC_LEVEL_VERBOSE,
			diagnosticOutputs,
		};

		PM_QUERY_ELEMENT qels[] = {
			{.metric = PM_METRIC_PRESENTED_FPS, .stat = PM_STAT_AVG},
			{.metric = PM_METRIC_GPU_TEMPERATURE, .stat = PM_STAT_AVG, .deviceId = 1},
		};
		auto dq = session.RegisterDynamicQuery(qels);
		auto blobs = dq.MakeBlobContainer(1);

		try {
			auto tc = session.TrackProcess(targetPid);
			for (int i = 0; i < 40; ++i) {
				try {
					dq.Poll(tc, blobs);
					const auto pBytes = blobs.GetFirst();
					std::cout << "fps:" << *reinterpret_cast<double*>(&pBytes[qels[0].dataOffset])
						<< " temp:" << *reinterpret_cast<double*>(&pBytes[qels[1].dataOffset]) << std::endl;
				}
				catch (const pmapi::ApiErrorException& ex) {
					std::cerr << "poll error: " << ex.what() << std::endl;
				}
				std::this_thread::sleep_for(50ms);
			}
		}
		catch (const pmapi::ApiErrorException& ex) {
			std::cerr << "track error: " << ex.what() << std::endl;
		}
	}
	catch (const pmapi::Exception& ex) {
		std::fprintf(stderr, "presentmon client error: %s\n", ex.what());
		return 1;
	}

	return 0;
}
