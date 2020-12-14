<template>
  <div id="app">
    <a>Rede Ethereum:</a>
    <input type="text" v-model="network"/>
    <a>Endereço da Loja:</a>
    <input type="text" v-model="contractAddress" />
    <a>Endereço da Carteira:</a>
    <input type="text" v-model="walletAdress" />
    <button @click="goToShop">VISITAR</button>

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
  Music
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
  private name = "";
  private ownerAddress = "";
  private network = "";

  get canCallContractMethods(): boolean {
    return this.contractAddress.length != 0;
  }

  get isOwner(): boolean {
    return this.ownerAddress == this.walletAddress;
  }

  private changeToBuyer(): BuyerMusicStoreContract {
    if (!(this.contract instanceof BuyerMusicStoreContract)) {
      this.contract = new BuyerMusicStoreContract(
        this.walletAddress,
        this.contractAddress
      );
    }

    return this.contract;
  }

  private changeToOwner(): OwnerMusicStoreContract {
    if (!(this.contract instanceof OwnerMusicStoreContract)) {
      this.contract = new OwnerMusicStoreContract(
        this.walletAddress,
        this.contractAddress
      );
    }

    return this.contract;
  }

  private setOwnerAddress(owner: string): void {
    this.ownerAddress = owner;
    this.changeToOwner();
  }

  private async goToShop(): Promise<void> {
    OwnerMusicStoreContract.setProvider(this.network);
    const contract = this.changeToBuyer();
    const contractOwner = contract.owner();
    const listAvailableMusics = contract.listAvailableMusics();

    const [owner, available] = await Promise.all([
      contractOwner,
      listAvailableMusics
    ]);

    this.setOwnerAddress(owner);
    const bought = this.isOwner ? [] : await contract.listBoughtMusics();

    available.forEach(
      m => ((m as MusicListItem).isBought = !!bought.find(b => b.id == m.id))
    );

    this.availableMusics = available as MusicListItem[];
  }

  private async buyMusic(music: MusicListItem): Promise<void> {
    const contract = this.changeToBuyer();
    await contract.buyMusic(music.name, music.price);
    music.isBought = true;
  }

  private async getMusicContent(music: MusicListItem): Promise<void> {
    const contract = this.changeToBuyer();
    const bytes = await contract.getMusicContent(music.name);
    await downloadFile(music.name, bytes);
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
