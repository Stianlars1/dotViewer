#pragma once

#include <sstream>
#include <string>
#include <type_traits>

namespace boost {

template <typename Target, typename Source>
Target lexical_cast(const Source& value) {
    static_assert(std::is_same<Target, std::string>::value,
                  "dotViewer minimal boost::lexical_cast only supports std::string");
    std::ostringstream oss;
    oss << value;
    return oss.str();
}

} // namespace boost
