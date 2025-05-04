# DIGGS Units Conversion API

## Overview

The DIGGS Units Conversion API provides a standardized way to convert values between different units of measurement using the DIGGS Units Dictionary. This service ensures accurate and consistent unit conversions across engineering and geotechnical applications.

## Base URL

```
https://api.example.com
```

Replace `api.example.com` with your actual production server address.

## Authentication

All API requests require an API key passed as a header:

```
X-API-Key: your_api_key
```

Contact your administrator to obtain an API key.

## Endpoints

### 1. Convert Units

Convert a value from one unit to another.

**Endpoint:** `/api/convert`

**Methods:** `GET`, `POST`

**Parameters:**

| Parameter   | Type   | Required | Description                                   |
|-------------|--------|----------|-----------------------------------------------|
| sourceValue | number | Yes      | The numeric value to convert                  |
| sourceUnit  | string | Yes      | The unit symbol of the source value           |
| targetUnit  | string | Yes      | The unit symbol to convert to                 |

**Example Request (GET):**

```
GET /api/convert?sourceValue=50&sourceUnit=psi&targetUnit=MPa
```

**Example Request (POST):**

```
POST /api/convert
Content-Type: application/json

{
  "sourceValue": 50,
  "sourceUnit": "psi",
  "targetUnit": "MPa"
}
```

**Example Response:**

```json
{
  "sourceValue": 50,
  "sourceUnit": "psi",
  "targetValue": 0.344738,
  "targetUnit": "MPa",
  "baseValue": 344738,
  "baseUnit": "Pa",
  "isExact": true,
  "quantityClass": "pressure"
}
```

**Error Responses:**

```json
{
  "error": "Units are not compatible. They must belong to the same quantity class."
}
```

```json
{
  "error": "One or both units not found in dictionary"
}
```

```json
{
  "error": "Source value must be a valid number"
}
```

### 2. Get Units for a Quantity Class

Retrieve all available units for a specific quantity class.

**Endpoint:** `/api/units/{quantity_class_name}`

**Method:** `GET`

**Parameters:**

| Parameter          | Type   | Required | Description                      |
|--------------------|--------|----------|----------------------------------|
| quantity_class_name | string | Yes      | The name of the quantity class   |

**Example Request:**

```
GET /api/units/pressure
```

**Example Response:**

```json
{
  "quantityClass": "pressure",
  "baseUnit": "Pa",
  "units": ["Pa", "kPa", "MPa", "GPa", "bar", "psi", "ksi", "atm"]
}
```

**Error Response:**

```json
{
  "error": "Quantity class not found"
}
```

### 3. List All Quantity Classes

Get all available quantity classes.

**Endpoint:** `/api/quantityclasses`

**Method:** `GET`

**Example Request:**

```
GET /api/quantityclasses
```

**Example Response:**

```json
[
  {
    "name": "Length",
    "baseUnit": "m"
  },
  {
    "name": "Area",
    "baseUnit": "m2"
  },
  {
    "name": "Volume",
    "baseUnit": "m3"
  },
  {
    "name": "Pressure",
    "baseUnit": "Pa"
  },
  {
    "name": "thermodynamic temperature",
    "baseUnit": "K"
  }
]
```

### 4. Health Check

Check the API's operational status.

**Endpoint:** `/api/health`

**Method:** `GET`

**Example Request:**

```
GET /api/health
```

**Example Response (Healthy):**

```json
{
  "status": "healthy",
  "dictionary_status": "available"
}
```

**Example Response (Degraded):**

```json
{
  "status": "degraded",
  "dictionary_status": "unavailable",
  "error": "Failed to fetch units dictionary"
}
```

## Rate Limits

The API has the following rate limits:

- 200 requests per day per API key
- 50 requests per hour per API key
- 10 requests per minute per endpoint

Exceeding these limits will result in a `429 Too Many Requests` response.

## DIGGS Units Dictionary

This API uses the official DIGGS Units Dictionary located at:

```
https://diggsml.org/def/units/DiggsUomDictionary.xml
```

The dictionary defines all available units, quantity classes, and conversion parameters. All conversions are performed according to the formulas and parameters specified in this dictionary.

## Conversion Formulas

Conversions use the following formulas:

1. **To base unit**: y = (A + Bx) / (C + Dx)
2. **From base unit**: z = (A - Cy) / (Dy - B)

Where:
- x is the source value
- y is the value in base units
- z is the target value
- A, B, C, D are conversion parameters from the DIGGS Units Dictionary

## Error Handling

The API uses standard HTTP status codes:

- 200: Success
- 400: Bad request (invalid parameters)
- 401: Unauthorized (invalid or missing API key)
- 404: Not found
- 429: Too many requests (rate limit exceeded)
- 500: Internal server error

Error responses include a JSON object with an `error` field containing a description of the error.

## Examples

### Example 1: Convert Pressure

**Request:**
```
GET /api/convert?sourceValue=100&sourceUnit=kPa&targetUnit=psi
```

**Response:**
```json
{
  "sourceValue": 100,
  "sourceUnit": "kPa",
  "targetValue": 14.5038,
  "targetUnit": "psi",
  "baseValue": 100000,
  "baseUnit": "Pa",
  "isExact": true,
  "quantityClass": "Pressure"
}
```

### Example 2: Convert Temperature

**Request:**
```
POST /api/convert
Content-Type: application/json

{
  "sourceValue": 25,
  "sourceUnit": "C",
  "targetUnit": "F"
}
```

**Response:**
```json
{
  "sourceValue": 25,
  "sourceUnit": "C",
  "targetValue": 77,
  "targetUnit": "F",
  "baseValue": 298.15,
  "baseUnit": "K",
  "isExact": true,
  "quantityClass": "Temperature"
}
```

## Support

For API support, please contact:
- Email: support@example.com
- Phone: (123) 456-7890
