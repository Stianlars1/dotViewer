import Foundation

/// GAP test transcripts contain prompts and expected output, not just GAP source.
/// Return one group per test case, and independent ranges for #@ directive expressions.
enum GAPTestInputRanges {
    static func collect(from root: TSNode, shouldCancel: (() -> Bool)?) -> [[TSRange]]? {
        var groups: [[TSRange]] = []
        var pending = [root]
        while let node = pending.popLast() {
            if shouldCancel?() == true { return nil }
            let type = String(cString: ts_node_type(node))
            if type == "test_case" {
                var input: [TSRange] = []
                for index in 0..<ts_node_named_child_count(node) {
                    if index % 200 == 0, shouldCancel?() == true { return nil }
                    let child = ts_node_named_child(node, index)
                    if String(cString: ts_node_type(child)) == "input_line", let range = range(for: child) {
                        input.append(range)
                    }
                }
                if !input.isEmpty { groups.append(input) }
            } else if type == "gap_expression" {
                if let range = range(for: node) { groups.append([range]) }
            } else {
                for index in (0..<ts_node_named_child_count(node)).reversed() {
                    pending.append(ts_node_named_child(node, index))
                }
            }
        }
        return groups
    }

    private static func range(for node: TSNode) -> TSRange? {
        let start = ts_node_start_byte(node)
        let end = ts_node_end_byte(node)
        guard start < end else { return nil }
        return TSRange(start_point: ts_node_start_point(node), end_point: ts_node_end_point(node), start_byte: start, end_byte: end)
    }
}
