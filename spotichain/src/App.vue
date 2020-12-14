<template>
  <div id="app">
    <div>
      <a
        >Endereço da Carteira:
        {{ walletAddress || "Não conectado a carteira" }}</a
      >
    </div>
    <div>
      <a>Endereço da Loja:</a>
      <input type="text" v-model="contractAddress" />
      <button @click="goToShop">VISITAR</button>
    </div>

    <div v-if="isOwner">
      <a>Adicionar Música:</a>
      <input type="file" ref="addMusicFileInput" />
      <a>Preço (em wei):</a>
      <input type="number" v-model="price" />
      <button @click="addMusic">ADICIONAR</button>
    </div>

    <table v-if="!!availableMusics.length">
      <tr>
        <th>Nome</th>
        <th>Preço</th>
        <th>Ações</th>
      </tr>
      <tr v-for="music in availableMusics" :key="music.id">
        <td>{{ music.name }}</td>
        <td>{{ music.price }}</td>
        <td>
          <button v-if="music.isBought" @click="getMusicContent(music)">
            BAIXAR
          </button>
          <button v-else @click="buyMusic(music)">
            COMPRAR
          </button>
        </td>
      </tr>
    </table>
  </div>
</template>

<script lang="ts">
import { Component, Vue } from "vue-property-decorator";
import {
  BuyerMusicStoreContract,
  OwnerMusicStoreContract,
  Music,
  metamaskConnect
} from "./Contract";
import { downloadFile } from "./download";
import Web3 from "web3";

type MusicListItem = Music & { isBought: boolean };

@Component({})
export default class App extends Vue {
  private contract?: BuyerMusicStoreContract | OwnerMusicStoreContract;
  private contractAddress = "";
  private walletAddress = "";
  private availableMusics: MusicListItem[] = [];
  private ownerAddress = "";
  private price = 0;

  get canCallContractMethods(): boolean {
    return this.contractAddress.length !== 0;
  }

  get isOwner(): boolean {
    return (
      this.ownerAddress.length !== 0 && this.ownerAddress === this.walletAddress
    );
  }

  private translateAddress(addr: string): string {
    addr = addr.toLocaleUpperCase().slice(2);
    return `0x${addr}`;
  }

  private async changeToBuyer(): Promise<BuyerMusicStoreContract> {
    if (this.contract == undefined) {
      this.walletAddress = this.translateAddress(await metamaskConnect());
    }
    if (!(this.contract instanceof BuyerMusicStoreContract)) {
      this.contract = new BuyerMusicStoreContract(this.contractAddress);
    }

    return this.contract;
  }

  private async changeToOwner(): Promise<OwnerMusicStoreContract> {
    if (this.contract == undefined) {
      this.walletAddress = this.translateAddress(await metamaskConnect());
    }
    if (!(this.contract instanceof OwnerMusicStoreContract)) {
      this.contract = new OwnerMusicStoreContract(this.contractAddress);
    }

    return this.contract;
  }

  private setOwnerAddress(owner: string): void {
    this.ownerAddress = this.translateAddress(owner);
    this.changeToOwner();
  }

  private async goToShop(): Promise<void> {
    const contract = await this.changeToBuyer();
    const contractOwner = contract.owner();
    const listAvailableMusics = contract.listAvailableMusics();

    const [owner, available] = await Promise.all([
      contractOwner,
      listAvailableMusics
    ]);

    this.setOwnerAddress(owner);
    const bought = this.isOwner ? [] : await contract.listBoughtMusics();

    this.availableMusics = available.map(m => ({
      id: m.id,
      name: m.name,
      price: m.price,
      isBought: !!bought.find(b => b.id == m.id)
    }));
  }

  private async buyMusic(music: MusicListItem): Promise<void> {
    const contract = await this.changeToBuyer();
    await contract.buyMusic(music.name, music.price);
    this.$set(music, "isBought", true);
  }

  private async getMusicContent(music: MusicListItem): Promise<void> {
    const contract = await this.changeToBuyer();
    const bytes = await contract.getMusicContent(music.name);
    await downloadFile(music.name, bytes);
  }

  private async addMusic(): Promise<void> {
    const file = (this.$refs.addMusicFileInput as HTMLInputElement).files!.item(
      0
    );
    if (!file) throw "missing file";

    const contract = await this.changeToOwner();

    contract.addMusic(file, this.price);
  }
}
</script>

<style>
#app {
  font-family: Avenir, Helvetica, Arial, sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  text-align: center;
  color: #2c3e50;
  margin-top: 60px;
}
</style>
