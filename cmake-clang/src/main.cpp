#include <IntelPresentMon/PresentMonAPIWrapper/PresentMonAPIWrapper.h>
#include <iostream>
#include <chrono>
#include <thread>

using namespace std::literals;

int main(int argc, const char** argv)
{
	// open a session with the service
	pmapi::Session session;

	// register a query for FPS and temperature (hardcoding gpu device id for most common case)
	PM_QUERY_ELEMENT qels[] = {
		{.metric = PM_METRIC_PRESENTED_FPS, .stat = PM_STAT_AVG},
		{.metric = PM_METRIC_GPU_TEMPERATURE, .stat = PM_STAT_AVG, .deviceId = 1},
	};
	auto dq = session.RegisterDyanamicQuery(qels);
	// data blob for receiving query results conveniently allocated using the registered query object
	auto blobs = dq.MakeBlobContainer(1);

	// begin tracking target application
	auto tc = session.TrackProcess(std::stoi(argv[1]));

	while (true) {
		// poll the tracked application using our query, result goes into our data blob
		dq.Poll(tc, blobs);
		// use the offsets in the query element list (written during registration) to access results
		const auto pBytes = blobs.GetFirst();
		std::cout << "fps:" << *reinterpret_cast<double*>(&pBytes[qels[0].dataOffset])
			<< " temp:" << *reinterpret_cast<double*>(&pBytes[qels[1].dataOffset]) << std::endl;
		// poll every 50ms
		std::this_thread::sleep_for(50ms);
	}

	return 0;
}