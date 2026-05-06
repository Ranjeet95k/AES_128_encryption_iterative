import argparse
import sys
import time


DEFAULT_PLAIN = "41 42 43 44 45 46 47 48 49 4a 4b 4c 4d 4e 4f 51"
DEFAULT_KEY = "00 01 02 03 04 05 06 07 08 09 0a 0b 0c 0d 0e 0f"
DEFAULT_EXPECTED = "26 82 c7 cc 07 bf 0f 58 5d b9 a9 2a 5d ed b2 5f"


def parse_args():
    parser = argparse.ArgumentParser(
        description="Send plaintext, key, and expected AES-128 ciphertext to a Basys 3 UART verifier."
    )
    parser.add_argument("port_arg", nargs="?", help="Serial port, for example COM9")
    parser.add_argument("--port", dest="port_opt", help="Serial port, for example COM9")
    parser.add_argument("--baud", type=int, default=115200, help="UART baud rate")
    parser.add_argument(
        "--plain",
        "--plaintext",
        dest="plain",
        default=DEFAULT_PLAIN,
        help="16-byte plaintext as hex",
    )
    parser.add_argument("--key", default=DEFAULT_KEY, help="16-byte AES key as hex")
    parser.add_argument(
        "--expected",
        default=DEFAULT_EXPECTED,
        help="16-byte expected ciphertext as hex",
    )
    parser.add_argument(
        "--payload",
        help="Optional 48-byte hex payload: plaintext + key + expected ciphertext",
    )
    parser.add_argument("--timeout", type=float, default=5.0, help="Read timeout in seconds")
    parser.add_argument("--startup-delay", type=float, default=2.0, help="Delay after opening serial port")
    args = parser.parse_args()
    args.port = args.port_opt or args.port_arg
    if not args.port:
        parser.error("serial port is required, for example: COM9")
    return args


def validate_block(name, value):
    try:
        block = bytes.fromhex(value)
    except ValueError as exc:
        raise ValueError(f"{name} must be valid hexadecimal") from exc

    if len(block) != 16:
        raise ValueError(f"{name} must be exactly 16 bytes; got {len(block)}")
    return block


def validate_payload(value):
    try:
        payload = bytes.fromhex(value)
    except ValueError as exc:
        raise ValueError("Payload must be valid hexadecimal") from exc

    if len(payload) != 48:
        raise ValueError(f"Payload must be exactly 48 bytes; got {len(payload)}")
    return payload[0:16], payload[16:32], payload[32:48]


def ascii_preview(block):
    chars = []
    for byte in block:
        chars.append(chr(byte) if 32 <= byte <= 126 else ".")
    return "".join(chars)


def print_block(label, block):
    print(f"{label} HEX:      {block.hex(' ').upper()}")
    print(f"{label} ASCII:    {ascii_preview(block)}")


def main():
    args = parse_args()

    try:
        import serial
    except ImportError:
        print("pyserial is not installed. Run: pip install pyserial")
        sys.exit(1)

    try:
        if args.payload:
            plaintext, key, expected = validate_payload(args.payload)
        else:
            plaintext = validate_block("Plaintext", args.plain)
            key = validate_block("Key", args.key)
            expected = validate_block("Expected ciphertext", args.expected)
    except ValueError as exc:
        print(f"ERROR: {exc}")
        sys.exit(1)

    payload = plaintext + key + expected

    print(f"Opening {args.port} at {args.baud} baud")
    with serial.Serial(args.port, args.baud, timeout=args.timeout) as ser:
        time.sleep(args.startup_delay)
        ser.reset_input_buffer()
        ser.reset_output_buffer()

        print_block("Plain", plaintext)
        print_block("Key", key)
        print_block("Expected", expected)

        ser.write(payload)
        ser.flush()
        received = ser.read(16)

    print_block("Received", received)

    if len(received) != 16:
        print(f"FAIL: expected 16 bytes back, received {len(received)} bytes")
        sys.exit(2)

    if received == expected:
        print("PASS")
    else:
        print("FAIL")
        sys.exit(3)


if __name__ == "__main__":
    main()
