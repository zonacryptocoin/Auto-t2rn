from web3 import Web3
from eth_account import Account
import time
import os
import random
from data_bridge import data_bridge
from keys import private_keys, labels
from network_config import networks

def center_text(text):
    terminal_width = os.get_terminal_size().columns
    lines = text.splitlines()
    centered_lines = [line.center(terminal_width) for line in lines]
    return "\n".join(centered_lines)

def clear_terminal():
    os.system('cls' if os.name == 'nt' else 'clear')

description = """
Auto Bridge Bot - t3rn Network
"""

chain_symbols = {
    'Base': '\033[34m',
    'OP Sepolia': '\033[91m',
}

green_color = '\033[92m'
reset_color = '\033[0m'
menu_color = '\033[95m'

explorer_urls = {
    'Base': 'https://sepolia.base.org',
    'OP Sepolia': 'https://sepolia-optimism.etherscan.io/tx/'
}

def get_balance(web3, address):
    balance = web3.eth.get_balance(address)
    return web3.from_wei(balance, 'ether')

def send_transaction(web3, account, address, data, network_name):
    nonce = web3.eth.get_transaction_count(address, 'pending')
    value_in_wei = web3.to_wei(0.2, 'ether')
    
    transaction = {
        'nonce': nonce,
        'to': networks[network_name]['contract_address'],
        'value': value_in_wei,
        'gas': 21000,
        'gasPrice': web3.eth.gas_price,
        'chainId': networks[network_name]['chain_id'],
        'data': data
    }
    
    signed_txn = web3.eth.account.sign_transaction(transaction, account.key)
    tx_hash = web3.eth.send_raw_transaction(signed_txn.raw_transaction)
    return web3.to_hex(tx_hash)

def process_transactions(network_name, bridges, chain_data):
    web3 = Web3(Web3.HTTPProvider(chain_data['rpc_url']))
    while not web3.is_connected():
        time.sleep(5)
        web3 = Web3(Web3.HTTPProvider(chain_data['rpc_url']))
    
    for bridge in bridges:
        for i, private_key in enumerate(private_keys):
            account = Account.from_key(private_key)
            address = account.address
            data = data_bridge.get(bridge)
            
            if not data:
                continue
            
            tx_hash = send_transaction(web3, account, address, data, network_name)
            print(f"{chain_symbols[network_name]}Transaction sent: {tx_hash}{reset_color}")
            time.sleep(random.uniform(60, 80))

def main():
    print(center_text(description))
    current_network = 'OP Sepolia'
    alternate_network = 'Base'
    
    while True:
        web3 = Web3(Web3.HTTPProvider(networks[current_network]['rpc_url']))
        while not web3.is_connected():
            time.sleep(5)
            web3 = Web3(Web3.HTTPProvider(networks[current_network]['rpc_url']))
        
        address = Account.from_key(private_keys[0]).address
        balance = get_balance(web3, address)
        
        if balance < 0.2:
            current_network, alternate_network = alternate_network, current_network
        
        process_transactions(current_network, ["Base - OP Sepolia"] if current_network == 'Base' else ["OP - Base"], networks[current_network])
        time.sleep(random.uniform(30, 60))

if __name__ == "__main__":
    main()
