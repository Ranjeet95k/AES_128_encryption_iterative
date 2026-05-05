import argparse
import sys
import time

try:
    import serial
except ImportError:
    print("pyserial is not installed. Run: pip install pyserial")
    sys.exit(1)


DEFAULT_PLAINTEXT = "41 42 43 44 45 46 47 48 49 4a 4b 4c 4d 4e 4f 52"
DEFAULT_KEY = "00 01 02 03 04 05 06 07 08 09 0a 0b 0c 0d 0e 0f"
DEFAULT_EXPECTED = "c8 f7 d4 3c d9 8f 2e 5a e1 10 01 07 71 70 58 71"


def parse_args():
    parser = argparse.ArgumentParser(
        description="Send AES-128 plaintext/key bytes to Basys 3 UART and read ciphertext."
    )
    parser.add_argument("--port", required=True, help="Serial port, for example COM5")
    parser.add_argument("--baud", type=int, default=115200, help="UART baud rate")
    parser.add_argument("--plaintext", default=DEFAULT_PLAINTEXT, help="16-byte plaintext hex")
    parser.add_argument("--key", default=DEFAULT_KEY, help="16-byte key hex")
    parser.add_argument("--expected", default=DEFAULT_EXPECTED, help="16-byte expected ciphertext hex")
    parser.add_argument("--timeout", type=float, default=5.0, help="Read timeout in seconds")
    parser.add_argument("--startup-delay", type=float, default=2.0, help="Delay after opening serial port")
    return parser.parse_args()


def validate_block(name, value):
    block = bytes.fromhex(value)
    if len(block) != 16:
        raise ValueError(f"{name} must be exactly 16 bytes.")
    return block


def main():
    args = parse_args()

    plaintext = validate_block("Plaintext", args.plaintext)
    key = validate_block("Key", args.key)
    expected = validate_block("Expected ciphertext", args.expected)

    payload = plaintext + key

    print(f"Opening {args.port} at {args.baud} baud")
    with serial.Serial(args.port, args.baud, timeout=args.timeout) as ser:
        time.sleep(args.startup_delay)
        ser.reset_input_buffer()
        ser.reset_output_buffer()

        print("Sending plaintext:", plaintext.hex(" "))
        print("Sending key      :", key.hex(" "))
        ser.write(payload)
        ser.flush()

        out = ser.read(16)

    print("Received hex    :", out.hex(" "))
    print("Expected hex    :", expected.hex(" "))

    if len(out) != 16:
        print(f"ERROR: expected 16 bytes back, received {len(out)} bytes")
        sys.exit(2)

    if out == expected:
        print("ENCRYPTION SUCCESS")
    else:
        print("ENCRYPTION FAILED")
        sys.exit(3)


if __name__ == "__main__":
    main()
