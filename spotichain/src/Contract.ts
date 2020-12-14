import { Contract, ContractSendMethod } from "web3-eth-contract";
import { bytesToHex, hexToBytes, AbiItem } from "web3-utils";

type Web3EthContractModule = {
  setProvider: (host: string) => void
} & (new (x: AbiItem[], y: string, z: { from: string }) => Contract);

const Web3Contract: Web3EthContractModule  = require("web3-eth-contract");

export type Music = {
  id: number;
  name: string;
  price: number;
};

class MusicStoreContract {
  protected web3Contract: Contract;
  private _owner?: string = undefined;
  private _name?: string = undefined;

  public static setProvider(host: string) {
    Web3Contract.setProvider(host);
  }

  constructor(walletAdress: string, contractAddress: string) {
    this.web3Contract = new Web3Contract([], contractAddress, {
      from: walletAdress
    });
  }

  public async listAvailableMusics(): Promise<Music[]> {
    return this.web3Contract.methods.listAvailableMusics().call();
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
  public async addMusic(
    name: string,
    price: number,
    file: File
  ): Promise<void> {
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
      .addMusic(name, price, bytesToHex(bytesBuffer))
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
    return this.web3Contract.methods.listAvailableMusics();
  }

  public async buyMusic(name: string, price: number): Promise<void> {
    await (this.web3Contract.methods.buyMusic(name) as ContractSendMethod).send({ 
      from: this.web3Contract.defaultAccount!,
      value: price,
     });
  }

  public async getMusicContent(name: string): Promise<number[]> {
    const result = await this.web3Contract.methods.getMusicContent(name).call();
    return hexToBytes(result);
  }
}
