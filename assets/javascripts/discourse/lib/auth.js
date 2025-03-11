/**
 * Extracts the Auth0 token for use with the Fabublox process selector.
 * This function attempts to retrieve the token from our custom endpoint.
 *
 * @returns {Promise<string>} A promise that resolves to the Auth0 token
 */
export async function extractToken() {
  try {
    // Try to fetch the token from our custom endpoint
    const response = await fetch("/auth/fabublox/token");

    if (!response.ok) {
      throw new Error(`Failed to fetch token: ${response.status} ${response.statusText}`);
    }

    const data = await response.json();

    if (data && data.token) {
      return data.token;
    } else {
      throw new Error("No token found in response");
    }
  } catch (error) {
    // In development mode, provide a fallback demo token
    if (window.location.hostname === "localhost" || window.location.hostname === "127.0.0.1") {
      return "dev_mode_demo_token";
    }

    throw error;
  }
}

/**
 * Legacy method for extracting token from Auth0 redirect.
 * This is kept for backward compatibility but may not be used
 * with the current implementation.
 */
export function extractTokenFromAuth0() {
  // No longer used - included for backwards compatibility
  return null;
}

/**
 * Validates the origin of a message to ensure it comes from an allowed source.
 *
 * @param {string} origin - The origin of the message
 * @returns {boolean} Whether the origin is valid
 */
export function validateMessage(origin) {
  // Allow messages from fabublox.com and its subdomains
  if (origin.endsWith("fabublox.com") || origin.includes(".fabublox.com")) {
    return true;
  }

  // Allow localhost and development environments
  if (origin.includes("localhost") || origin.includes("127.0.0.1")) {
    return true;
  }

  return false;
}