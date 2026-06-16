import re
import sys

def parse_python_engine(file_path: str) -> dict:
    with open(file_path, "r", encoding="utf-8") as f:
        content = f.read()
    
    # Extract base rates
    base_rates_match = re.search(r"BASE_RATES:\s*Dict\[str,\s*float\]\s*=\s*({[^}]+})", content)
    base_rates = eval(base_rates_match.group(1)) if base_rates_match else {}

    # Extract multipliers
    zoning_match = re.search(r"ZONING_MULTIPLIERS:\s*Dict\[str,\s*float\]\s*=\s*({[^}]+})", content)
    zoning_multipliers = eval(zoning_match.group(1)) if zoning_match else {}

    regional_match = re.search(r"REGIONAL_MULTIPLIERS:\s*Dict\[str,\s*float\]\s*=\s*({[^}]+})", content)
    regional_multipliers = eval(regional_match.group(1)) if regional_match else {}

    # Extract constants
    area_exponent = float(re.search(r"AREA_EXPONENT:\s*float\s*=\s*([\d\.]+)", content).group(1))
    coastal_decay = float(re.search(r"COASTAL_DECAY:\s*float\s*=\s*([\d\.]+)", content).group(1))

    return {
        "base_rates": base_rates,
        "zoning_multipliers": zoning_multipliers,
        "regional_multipliers": regional_multipliers,
        "area_exponent": area_exponent,
        "coastal_decay": coastal_decay
    }

def parse_php_service(file_path: str) -> dict:
    with open(file_path, "r", encoding="utf-8") as f:
        content = f.read()

    # Regex parses for PHP arrays
    base_rates = {}
    br_block = re.search(r"\$baseRates\s*=\s*\[([^\]]+)\]", content)
    if br_block:
        for match in re.finditer(r'"([^"]+)"\s*=>\s*([\d\.]+)', br_block.group(1)):
            base_rates[match.group(1)] = float(match.group(2))

    zoning = {}
    z_block = re.search(r"\$zoningMultipliers\s*=\s*\[([^\]]+)\]", content)
    if z_block:
        for match in re.finditer(r'"([^"]+)"\s*=>\s*([\d\.]+)', z_block.group(1)):
            zoning[match.group(1)] = float(match.group(2))

    regional = {}
    r_block = re.search(r"\$regionalMultipliers\s*=\s*\[([^\]]+)\]", content)
    if r_block:
        for match in re.finditer(r'"([^"]+)"\s*=>\s*([\d\.]+)', r_block.group(1)):
            regional[match.group(1)] = float(match.group(2))

    area_exponent = float(re.search(r"\$areaExponent\s*=\s*([\d\.]+)", content).group(1))
    coastal_decay = float(re.search(r"\$coastalDecay\s*=\s*([\d\.]+)", content).group(1))

    return {
        "base_rates": base_rates,
        "zoning_multipliers": zoning,
        "regional_multipliers": regional,
        "area_exponent": area_exponent,
        "coastal_decay": coastal_decay
    }

def parse_dart_client(file_path: str) -> dict:
    with open(file_path, "r", encoding="utf-8") as f:
        content = f.read()

    base_rates = {}
    br_block = re.search(r"baseRates\s*=\s*\{([^\}]+)\}", content)
    if br_block:
        for match in re.finditer(r"['\"]([^'\"]+)['\"]\s*:\s*([\d\.]+)", br_block.group(1)):
            base_rates[match.group(1)] = float(match.group(2))

    zoning = {}
    z_block = re.search(r"zoningMultipliers\s*=\s*\{([^\}]+)\}", content)
    if z_block:
        for match in re.finditer(r"['\"]([^'\"]+)['\"]\s*:\s*([\d\.]+)", z_block.group(1)):
            zoning[match.group(1)] = float(match.group(2))

    regional = {}
    r_block = re.search(r"regionalMultipliers\s*=\s*\{([^\}]+)\}", content)
    if r_block:
        for match in re.finditer(r"['\"]([^'\"]+)['\"]\s*:\s*([\d\.]+)", r_block.group(1)):
            regional[match.group(1)] = float(match.group(2))

    area_exponent = float(re.search(r"areaExponent\s*=\s*([\d\.]+)", content).group(1))
    coastal_decay = float(re.search(r"coastalDecay\s*=\s*([\d\.]+)", content).group(1))

    return {
        "base_rates": base_rates,
        "zoning_multipliers": zoning,
        "regional_multipliers": regional,
        "area_exponent": area_exponent,
        "coastal_decay": coastal_decay
    }

def main():
    print("[INFO] Executing Cross-Language Mathematical Parity Audit...")
    
    py_path = "backend-python/valuation_engine.py"
    php_path = "backend-php/src/services/ValuationService.php"
    dart_path = "lib/services/valuation_client.dart"

    try:
        py_data = parse_python_engine(py_path)
        php_data = parse_php_service(php_path)
        dart_data = parse_dart_client(dart_path)
    except Exception as e:
        print(f"[ERROR] Parser failure: {e}")
        sys.exit(1)

    discrepancies = []

    # Compare constants Python vs PHP
    if py_data["area_exponent"] != php_data["area_exponent"]:
        discrepancies.append(f"AREA_EXPONENT mismatch (Py vs PHP): Python={py_data['area_exponent']}, PHP={php_data['area_exponent']}")
    if py_data["coastal_decay"] != php_data["coastal_decay"]:
        discrepancies.append(f"COASTAL_DECAY mismatch (Py vs PHP): Python={py_data['coastal_decay']}, PHP={php_data['coastal_decay']}")

    # Compare constants Python vs Dart
    if py_data["area_exponent"] != dart_data["area_exponent"]:
        discrepancies.append(f"AREA_EXPONENT mismatch (Py vs Dart): Python={py_data['area_exponent']}, Dart={dart_data['area_exponent']}")
    if py_data["coastal_decay"] != dart_data["coastal_decay"]:
        discrepancies.append(f"COASTAL_DECAY mismatch (Py vs Dart): Python={py_data['coastal_decay']}, Dart={dart_data['coastal_decay']}")

    # Compare dicts
    for category in ["base_rates", "zoning_multipliers", "regional_multipliers"]:
        py_dict = py_data[category]
        php_dict = php_data[category]
        dart_dict = dart_data[category]

        # Key sets
        if set(py_dict.keys()) != set(php_dict.keys()):
            discrepancies.append(f"Key set mismatch in {category} (Py vs PHP): Python={set(py_dict.keys())}, PHP={set(php_dict.keys())}")
        if set(py_dict.keys()) != set(dart_dict.keys()):
            discrepancies.append(f"Key set mismatch in {category} (Py vs Dart): Python={set(py_dict.keys())}, Dart={set(dart_dict.keys())}")
        
        # Value matches
        for k in py_dict:
            if k in php_dict and py_dict[k] != php_dict[k]:
                discrepancies.append(f"Value mismatch in {category} for key '{k}' (Py vs PHP): Python={py_dict[k]}, PHP={php_dict[k]}")
            if k in dart_dict and py_dict[k] != dart_dict[k]:
                discrepancies.append(f"Value mismatch in {category} for key '{k}' (Py vs Dart): Python={py_dict[k]}, Dart={dart_dict[k]}")

    if discrepancies:
        print("\n[FAIL] Audit FAILED. Found the following mismatches:")
        for d in discrepancies:
            print(f"  - {d}")
        sys.exit(1)
    else:
        print("\n[SUCCESS] Audit PASSED. Multi-language (Python, PHP, Dart) algorithms are 100% synchronized.")
        print(f"  - Base Rates: {list(py_data['base_rates'].keys())}")
        print(f"  - Zoning Multipliers: {list(py_data['zoning_multipliers'].keys())}")
        print(f"  - Regional Multipliers: {list(py_data['regional_multipliers'].keys())}")
        print(f"  - Area Power Exponent: {py_data['area_exponent']}")
        print(f"  - Coastal Proximity Decay Constant: {py_data['coastal_decay']}")

if __name__ == "__main__":
    main()
