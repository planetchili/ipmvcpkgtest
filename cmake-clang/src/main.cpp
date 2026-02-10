#include <vector>
#include <span>
#include <string>
#include <format>
#include <iostream>
#include <unordered_map>
#include <functional>
#include <optional>
#include <ranges>
#include <memory>
#include <array>
#include <cstdint>
#include <algorithm>
#include <numeric>

namespace
{
    // A global volatile sink to discourage the optimizer from discarding work.
    // We still also emit to std::cout to force observable side effects.
    volatile std::uint64_t g_sink = 0;

    template <class T>
    inline void consume(const T& v)
    {
        // Use std::hash to pull in templates and produce a value that we can accumulate.
        g_sink ^= static_cast<std::uint64_t>(std::hash<T>{}(v)) + 0x9e3779b97f4a7c15ull + (g_sink << 6) + (g_sink >> 2);
    }

    inline void consume_u64(std::uint64_t v)
    {
        g_sink ^= v + 0x9e3779b97f4a7c15ull + (g_sink << 6) + (g_sink >> 2);
    }
}

int main(int argc, const char** argv)
{
    // ---- string + iostream + format ----
    std::string arg0 = (argc > 0 && argv && argv[0]) ? std::string(argv[0]) : std::string("app");
    std::string arg1 = (argc > 1 && argv[1]) ? std::string(argv[1]) : std::string("default");
    std::string joined = std::format("{}:{}", arg0, arg1);
    std::cout << std::format("args: argc={}, joined='{}'\n", argc, joined);

    // ---- vector (4+ instantiations) ----
    std::vector<int> v_int;
    std::vector<double> v_dbl;
    std::vector<std::string> v_str;
    std::vector<std::uint8_t> v_u8;

    const int n = std::max(8, (argc > 0 ? argc : 1) * 8);

    v_int.reserve(static_cast<size_t>(n));
    v_dbl.reserve(static_cast<size_t>(n));
    v_str.reserve(static_cast<size_t>(n / 2));
    v_u8.reserve(static_cast<size_t>(n));

    for (int i = 0; i < n; ++i)
    {
        v_int.push_back(i + static_cast<int>(joined.size()));
        v_dbl.push_back(1.0 / (1.0 + i) + (argc > 1 ? 0.25 : 0.0));
        v_u8.push_back(static_cast<std::uint8_t>((i * 17) ^ (argc * 13)));

        if ((i % 2) == 0)
        {
            v_str.push_back(std::format("s{}:{}", i, arg1));
        }
    }

    // ---- array ----
    std::array<int, 8> a_int = { 3, 1, 4, 1, 5, 9, 2, 6 };
    std::array<char, 16> a_tag = { 'b','u','i','l','d','-','s','i','z','e','-','t','e','s','t','\0' };

    // ---- span (4+ instantiations) ----
    std::span<int> sp_int(v_int);
    std::span<const double> sp_dbl(v_dbl);
    std::span<const std::uint8_t> sp_u8(v_u8);
    std::span<const int, 8> sp_aint(a_int);

    // Also exercise a span over string storage.
    std::span<const char> sp_chars(joined.data(), joined.size());

    // ---- optional (4+ instantiations) ----
    std::optional<int> opt_i;
    std::optional<double> opt_d;
    std::optional<std::string> opt_s;
    std::optional<std::span<const std::uint8_t>> opt_sp;

    if ((argc % 2) == 0) opt_i = v_int.empty() ? 0 : v_int.back();
    if ((argc % 3) == 0) opt_d = v_dbl.empty() ? 0.0 : v_dbl.front();
    if ((argc % 5) == 0) opt_s = joined;
    if (!v_u8.empty())   opt_sp = sp_u8.subspan(0, std::min<size_t>(sp_u8.size(), 16));

    // Force use of optionals in a way the optimizer can't trivially remove.
    consume_u64(static_cast<std::uint64_t>(opt_i.value_or(-1)));
    consume_u64(static_cast<std::uint64_t>(static_cast<long long>(opt_d.value_or(-1.0) * 1000000.0)));
    if (opt_s) consume(*opt_s); else consume(joined);

    if (opt_sp)
    {
        std::uint64_t local = 0;
        for (auto b : *opt_sp) local = (local * 131) + b;
        consume_u64(local);
    }

    // ---- unordered_map ----
    std::unordered_map<std::string, std::uint64_t> freq;
    freq.reserve(v_str.size() + 4);
    freq["argc"] = static_cast<std::uint64_t>(argc);
    freq["joined_len"] = static_cast<std::uint64_t>(joined.size());
    freq[std::string(a_tag.data())] = 1;

    for (const auto& s : v_str)
    {
        // Count by first character to keep it simple but non-trivial.
        std::string key = s.empty() ? std::string("empty") : std::string(1, s[0]);
        ++freq[key];
    }

    // ---- function ----
    std::function<std::uint64_t(int)> f1 = [&](int x) -> std::uint64_t {
        return static_cast<std::uint64_t>(x) * 1469598103934665603ull ^ static_cast<std::uint64_t>(joined.size());
        };
    std::function<std::uint64_t(double)> f2 = [&](double x) -> std::uint64_t {
        auto y = static_cast<long long>((x + 1.0) * 100000.0);
        return static_cast<std::uint64_t>(y) * 1099511628211ull;
        };
    std::function<std::string(const std::string&)> f3 = [&](const std::string& s) -> std::string {
        return std::format("[{}|{}]", s, joined);
        };
    std::function<std::uint64_t(std::span<const char>)> f4 = [&](std::span<const char> s) -> std::uint64_t {
        std::uint64_t h = 1469598103934665603ull;
        for (char c : s) h = (h ^ static_cast<unsigned char>(c)) * 1099511628211ull;
        return h;
        };

    consume_u64(f1(n));
    consume_u64(f2(v_dbl.empty() ? 0.0 : v_dbl[0]));
    consume(f3(arg1));
    consume_u64(f4(sp_chars));

    // ---- ranges ----
    // Transform + filter via views, then materialize into a vector to exercise templates/allocations.
    auto even_sq_view =
        v_int
        | std::views::filter([](int x) { return (x % 2) == 0; })
        | std::views::transform([](int x) { return x * x; });

    std::vector<long long> v_sq;
    for (int x : even_sq_view)
        v_sq.push_back(static_cast<long long>(x));

    // Use ranges algorithms too.
    std::ranges::sort(v_sq);
    if (!v_sq.empty())
        consume_u64(static_cast<std::uint64_t>(v_sq.back()));

    // Aggregate over spans to ensure span codepaths are used.
    std::uint64_t sum_int = 0;
    for (int x : sp_int) sum_int += static_cast<std::uint64_t>(x);

    double sum_dbl = 0.0;
    for (double x : sp_dbl) sum_dbl += x;

    std::uint64_t sum_a = 0;
    for (int x : sp_aint) sum_a += static_cast<std::uint64_t>(x);

    consume_u64(sum_int);
    consume_u64(static_cast<std::uint64_t>(sum_dbl * 1000000.0));
    consume_u64(sum_a);

    // ---- memory (unique_ptr + shared_ptr) ----
    auto up = std::make_unique<std::vector<int>>(v_int);
    auto sp = std::make_shared<std::unordered_map<std::string, std::uint64_t>>(freq);

    // Mutate through pointers to force real codegen.
    if (!up->empty())
    {
        (*up)[0] ^= static_cast<int>(g_sink & 0xFF);
        consume_u64(static_cast<std::uint64_t>((*up)[0]));
    }
    (*sp)["sink_low"] = static_cast<std::uint64_t>(g_sink & 0xFFFF);

    // Emit a summary so the compiler can't discard everything.
    std::cout << std::format(
        "summary: sink=0x{:016x}, v_int={}, v_dbl={}, v_str={}, map_keys={}\n",
        static_cast<std::uint64_t>(g_sink),
        v_int.size(), v_dbl.size(), v_str.size(), sp->size()
    );

    // Return a value dependent on runtime state to further discourage elision.
    return static_cast<int>((g_sink ^ sum_int ^ sum_a) & 0x7F);
}
