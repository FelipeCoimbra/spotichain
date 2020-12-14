import Web3 from "web3";
import { Contract, ContractSendMethod } from "web3-eth-contract";
import { AbiItem, bytesToHex, hexToBytes } from "web3-utils";
import ABI from "./contract.abi";

export type Music = {
  id: number;
  name: string;
  price: number;
};

declare global {
  interface Ethereum {
    isMetaMask: boolean;
    request(options: { method: "eth_requestAccounts" }): Promise<string[]>;
  }

  interface Window {
    ethereum: Ethereum | undefined;
  }
}

let web3: Web3 | undefined;

export async function metamaskConnect(): Promise<string> {
  if (!window.ethereum) {
    throw "missing metamask";
  }

  const accounts = await window.ethereum.request({
    method: "eth_requestAccounts"
  });
  web3 = new Web3(window.ethereum as any);
  web3.eth.defaultAccount = accounts[0];
  return accounts[0];
}

class MusicStoreContract {
  protected web3Contract: Contract;
  private _owner?: string = undefined;
  private _name?: string = undefined;

  constructor(contractAddress: string) {
    this.web3Contract = new web3!.eth.Contract(
      ABI as AbiItem[],
      contractAddress
    );
  }

  public async listAvailableMusics(): Promise<Music[]> {
    return (await this.web3Contract.methods.listAvailableMusics().call())[0];
  }

  public async owner(): Promise<string> {
    this._owner = await this.web3Contract.methods.owner().call();

    return this._owner!;
  }

  public async name(): Promise<string> {
    this._name = await this.web3Contract.methods.name().call();

    return this._name!;
  }
}

export class OwnerMusicStoreContract extends MusicStoreContract {
  public async addMusic(file: File, price: number): Promise<void> {
    const reader = new FileReader();
    reader.readAsArrayBuffer(file);
    const readPromise: Promise<ArrayBuffer> = new Promise(resolve => {
      reader.onloadend = () => resolve(reader.result as ArrayBuffer);
    });

    const buffer = new Uint8Array(await readPromise);
    const bytesBuffer = new Array(buffer.byteLength);
    for (let i = 0; i < buffer.byteLength; ++i) {
      bytesBuffer[i] = buffer[i];
    }
    await this.web3Contract.methods
      .addMusic(file.name, price, bytesToHex(bytesBuffer))
      .call();
  }

  public async hideMusic(name: string): Promise<void> {
    await this.web3Contract.methods.hideMusic(name).call();
  }

  public async showMusic(name: string): Promise<void> {
    await this.web3Contract.methods.showMusic(name).call();
  }

  public async withdraw(): Promise<void> {
    await this.web3Contract.methods.withdraw().call();
  }
}

export class BuyerMusicStoreContract extends MusicStoreContract {
  public async listBoughtMusics(): Promise<Music[]> {
    return this.web3Contract.methods.listBoughtMusics().call();
  }

  public async buyMusic(name: string, price: number): Promise<void> {
    await (this.web3Contract.methods.buyMusic(name) as ContractSendMethod).send(
      {
        from: web3!.defaultAccount!,
        value: price
      }
    );
  }

  public async getMusicContent(name: string): Promise<number[]> {
    const result = this.web3Contract.methods.getMusicContent(name).call();
    return hexToBytes(result);
  }
}
