# Clarity Art Registry  

## Overview  
Clarity Art Registry is a smart contract written in Clarity for the Stacks blockchain. It provides a decentralized registry for digital artwork, allowing artists to register their work, manage metadata, and enforce access controls.  

## Features  
- **Artwork Registration:** Store artwork details such as name, artist, dimensions, and categories.  
- **Ownership Management:** Transfer ownership of registered artworks.  
- **Permission System:** Restrict or grant access to view artwork details.  
- **Error Handling:** Uses structured error codes for better debugging.  
- **Validation Functions:** Ensure artwork metadata meets predefined criteria.  

## Smart Contract Functions  

### **1. Artwork Registration & Management**  
- `register-artwork (name, dimensions, notes, categories) → (uint)`  
  Registers a new artwork and returns a unique artwork ID.  
- `update-artwork (artwork-id, new-name, new-dimensions, new-notes, new-categories) → (bool)`  
  Updates existing artwork metadata.  
- `remove-artwork (artwork-id) → (bool)`  
  Deletes an artwork entry from the registry.  

### **2. Artwork Retrieval**  
- `get-full-artwork-details (artwork-id) → (object)`  
  Retrieves all metadata associated with an artwork.  
- `get-artwork-name (artwork-id) → (string)`  
  Returns the name of an artwork.  
- `get-artwork-artist (artwork-id) → (principal)`  
  Retrieves the registered artist of an artwork.  

### **3. Ownership & Access Control**  
- `transfer-artwork (artwork-id, new-artist) → (bool)`  
  Transfers artwork ownership to another user.  
- `check-viewer-access (artwork-id, viewer) → (bool)`  
  Checks if a specific user has permission to view an artwork.  
- `has-viewing-permission? (artwork-id, viewer) → (bool)`  
  Returns true if a user has access to an artwork.  

### **4. Validation & Utility Functions**  
- `validate-artwork-id (artwork-id) → (bool)`  
  Checks if an artwork ID is within a valid range.  
- `validate-name (name) → (bool)`  
  Ensures artwork name meets length requirements.  
- `validate-dimensions-range (artwork-id, min-dims, max-dims) → (bool)`  
  Verifies if artwork dimensions are within a specific range.  

## Deployment Instructions  
To deploy this contract on the Stacks blockchain:  
1. Install [Clarity](https://docs.stacks.co/clarity) and set up a local development environment.  
2. Compile the contract and deploy it using the Stacks CLI.  
3. Interact with the contract using Clarity REPL or a frontend dApp.  

## License  
This project is open-source under the MIT License.