defmodule TorchxTest do
  use ExUnit.Case, async: true

  doctest Torchx

  alias Torchx.Backend, as: TB

  # Torch Tensor creation shortcut
  defp tt(data, type \\ {:f, 32}), do: Nx.tensor(data, type: type, backend: TB)
  defp bt(data, type \\ {:f, 32}), do: Nx.tensor(data, type: type, backend: Nx.BinaryBackend)

  defp assert_equal(tt, data, type \\ {:f, 32}),
    do: assert(Nx.backend_transfer(tt) == Nx.tensor(data, type: type))

  describe "tensor" do
    test "add" do
      a = tt([[1, 2], [3, 4]], {:s, 8})
      b = tt([[5, 6], [7, 8]])

      c = Nx.add(a, b)

      assert_equal(c, [[6.0, 8.0], [10.0, 12.0]])
    end

    test "dot" do
      a = tt([[1, 2], [3, 4]])
      b = tt([[5, 6], [7, 8]])

      c = Nx.dot(a, b)

      assert_equal(c, [[19, 22], [43, 50]])
    end
  end


  @types [{:s, 8}, {:u, 8}, {:s, 16}, {:s, 32}, {:s, 64}, {:bf, 16}, {:f, 32}, {:f, 64}]
  @bf16_and_ints [{:s, 8}, {:u, 8}, {:s, 16}, {:s, 32}, {:s, 64}, {:bf, 16}]
  @ints [{:s, 8}, {:u, 8}, {:s, 16}, {:s, 32}, {:s, 64}]
  @ops [:add, :subtract, :divide, :remainder, :multiply, :power, :atan2, :min, :max]
  @bitwise_ops [:bitwise_and, :bitwise_or, :bitwise_xor, :left_shift, :right_shift]
  @logical_ops [:equal, :not_equal, :greater, :less, :greater_equal, :less_equal, :logical_and, :logical_or, :logical_xor]

  defp test_binary_op(op, data_a \\ [[1, 2], [3, 4]], data_b \\ [[5, 6], [7, 8]], type_a, type_b) do
    a = tt(data_a, type_a)
    b = tt(data_b, type_b)

    c = Kernel.apply(Nx, op, [a, b])

    binary_a = Nx.backend_transfer(a, Nx.BinaryBackend)
    binary_b = Nx.backend_transfer(b, Nx.BinaryBackend)
    binary_c = Kernel.apply(Nx, op, [binary_a, binary_b])

    assert(Nx.backend_transfer(c) == binary_c)
  end

  describe "binary tensor-tensor ops" do
    for op <- @ops ++ @logical_ops,
        type_a <- @types,
        type_b <- @types,
        not ((op in [:divide, :remainder, :atan2, :power] and (type_a == {:bf, 16} and type_b in @bf16_and_ints)) or
               (type_b == {:bf, 16} and type_a in @bf16_and_ints)) do
      test "#{op}(#{Nx.Type.to_string(type_a)}, #{Nx.Type.to_string(type_b)})" do
        op = unquote(op)
        type_a = unquote(type_a)
        type_b = unquote(type_b)

        test_binary_op(op, type_a, type_b)
      end
    end
  end

  describe "binary tensor-tensor bitwise ops" do
    for op <- @bitwise_ops,
        type_a <- @ints,
        type_b <- @ints do
      test "#{op}(#{Nx.Type.to_string(type_a)}, #{Nx.Type.to_string(type_b)})" do
        op = unquote(op)
        type_a = unquote(type_a)
        type_b = unquote(type_b)

        test_binary_op(op, type_a, type_b)
      end
    end
  end

  # Division with bfloat16 is a special case with PyTorch,
  # because it upcasts bfloat16 args to float for numerical accuracy purposes.
  # So, the result of division is different from what direct bf16 by bf16 division gives us.
  # I.e. 1/5 == 0.19921875 in direct bf16 division and 0.2001953125 when dividing floats
  # converting them to bf16 afterwards (PyTorch style).
  describe "bfloat16" do
    for type_a <- @bf16_and_ints,
        type_b <- @bf16_and_ints,
        type_a == {:bf, 16} or type_b == {:bf, 16} do
      test "divide(#{Nx.Type.to_string(type_a)}, #{Nx.Type.to_string(type_b)})" do
        type_a = unquote(type_a)
        type_b = unquote(type_b)

        a = tt([[1, 2], [3, 4]], type_a)
        b = tt([[5, 6], [7, 8]], type_b)

        c = Nx.divide(a, b)

        assert Nx.backend_transfer(c) ==
                 Nx.tensor([[0.2001953125, 0.333984375], [0.427734375, 0.5]],
                   type: {:bf, 16}
                 )
      end
    end

    for type_a <- @bf16_and_ints,
        type_b <- @bf16_and_ints,
        type_a == {:bf, 16} or type_b == {:bf, 16} do
      test "power(#{Nx.Type.to_string(type_a)}, #{Nx.Type.to_string(type_b)})" do
        type_a = unquote(type_a)
        type_b = unquote(type_b)

        a = tt([[1, 2], [3, 4]], type_a)
        b = tt([[5, 6], [7, 8]], type_b)

        c = Nx.power(a, b)

        assert Nx.backend_transfer(c) ==
                 Nx.tensor([[1.0, 64.0], [2192.0, 65536.0]],
                   type: {:bf, 16}
                 )
      end
    end
  end

  describe "vectors" do
    for type_a <- @types,
        type_b <- @types do
      test "outer(#{Nx.Type.to_string(type_a)}, #{Nx.Type.to_string(type_b)})" do
        type_a = unquote(type_a)
        type_b = unquote(type_b)

        test_binary_op(:outer, [1, 2, 3, 4], [5, 6, 7, 8], type_a, type_b)
      end
    end
  end
end
