#ifndef DENSE_RAM_NODE_HPP
#define DENSE_RAM_NODE_HPP

#include "node.hpp"
#include "binary.hpp"

#include <numeric>

namespace ramnet {
  class DenseRAMNode: public Node {
  public:
    DenseRAMNode(const size_t input_size);

    void train(const std::vector<bool>& encoded_input) override;
    void train(const size_t decoded_input) override;

    size_t size() const override;
    size_t hammingWeight() const override;

    bool fire(const std::vector<bool>& encoded_input) const override;
    bool fire(const size_t decoded_input) const override;

  private:
    size_t input_size;
    std::vector<bool> memory;
  };
};

#endif