import { cryptoFramework } from '@kit.CryptoArchitectureKit';

@Entry
@Component
struct Index {
  @State refreshing: boolean = false;
  @State lastSync: string = clock();
  @State messages: Msg[] = [
    msgFactory.make(12),
    msgFactory.make(30),
    msgFactory.make(48),
    msgFactory.make(66),
    msgFactory.make(84)
  ];

  @Builder
  card(m: Msg) {
    Column() {
      Row() {
        Text(m.sender)
          .fontSize(16)
          .textAlign(TextAlign.Start)
          .fontWeight(FontWeight.Medium)
          .fontColor('#FFFFFF')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)

        Text(age(m.at))
          .fontSize(13)
          .fontColor('#8E8E93')
          .margin({ left: 8 })
      }
      .width('100%')

      Text(m.preview)
        .fontSize(15)
        .textAlign(TextAlign.Start)
        .fontColor('#C7C7CC')
        .lineHeight(20)
        .maxLines(3)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')
        .margin({ top: 4 })
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(12)
    .borderRadius(16)
    .backgroundColor('#2C2C2E')
  }

  build() {
    Column() {
      Text(this.refreshing ? 'Updating...' : `Updated ${this.lastSync}`)
        .fontSize(13)
        .fontColor('#8E8E93')
        .width('100%')
        .height('21%')
        .textAlign(TextAlign.Center)

      Refresh({ refreshing: $$this.refreshing }) {
        List({ space: 8 }) {
          ForEach(this.messages, (m: Msg) => {
            ListItem() {
              this.card(m)
            }
          }, (m: Msg) => m.id)
        }
        .width('100%')
        .height('100%')
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
        .padding({ left: '7%', right: '7%', bottom: '16%' })
      }
      .refreshOffset(40)
      .pullToRefresh(true)
      .onRefreshing(() => {
        msgFactory.fetchNewer()
          .then((fresh: Msg[]) => {
            this.messages = fresh.concat(this.messages).slice(0, 20);
            this.lastSync = clock();
          })
          .finally(() => {
            this.refreshing = false;
          });
      })
      .layoutWeight(1)
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .padding(8)
    .backgroundColor('#000000')
  }
}


interface Msg {
  id: string;
  sender: string;
  preview: string;
  at: number;
}

const SENDERS: string[] = [
  'Robert Simpson', 'Elif Yilmaz',
  'Kerem Aydin', 'Cargo Tracking', 'Ayse Demir'
];

const PREVIEWS: string[] = [
  'Let me know when you leave home.',
  'Reminder: Your statement is ready.',
  'Are we still on for tomorrow?',
  'Your package is out for delivery.',
  'Meeting moved to 3pm.'
];

class MsgFactory {
  private seq: number = 0;

  make(ageMin: number): Msg {
    this.seq++;
    return {
      id: `m${this.seq}`,
      sender: secureRandom.pick(SENDERS),
      preview: secureRandom.pick(PREVIEWS),
      at: Date.now() - ageMin * 60000
    };
  }

  fetchNewer(): Promise<Msg[]> {
    return new Promise<Msg[]>((resolve) => {
      setTimeout(() => {
        const list: Msg[] = [];
        const n: number = secureRandom.range(1, 3);
        for (let i = 0; i < n; i++) {
          list.push(this.make(i));
        }
        resolve(list);
      }, 1100);
    });
  }
}

const msgFactory: MsgFactory = new MsgFactory();

function age(ts: number): string {
  const m: number = Math.floor((Date.now() - ts) / 60000);
  if (m < 1) {
    return 'now';
  }
  if (m < 60) {
    return `${m}m`;
  }
  const h: number = Math.floor(m / 60);
  return h < 24 ? `${h}h` : `${Math.floor(h / 24)}d`;
}

function clock(): string {
  const d: Date = new Date();
  const hh: string = d.getHours().toString().padStart(2, '0');
  const mm: string = d.getMinutes().toString().padStart(2, '0');
  return `${hh}:${mm}`;
}

class SecureRandom {
  private rand: cryptoFramework.Random = cryptoFramework.createRandom();

  private uint32(): number {
    const d: Uint8Array = this.rand.generateRandomSync(4).data;
    return (((d[0] << 24) | (d[1] << 16) | (d[2] << 8) | d[3]) >>> 0);
  }

  int(max: number): number {
    if (max <= 0) {
      throw new Error('max must be > 0');
    }
    const limit: number = Math.floor(0x100000000 / max) * max;
    let x: number = this.uint32();
    while (x >= limit) {
      x = this.uint32();
    }
    return x % max;
  }

  range(min: number, max: number): number {
    return min + this.int(max - min + 1);
  }

  pick<T>(arr: Array<T>): T {
    return arr[this.int(arr.length)];
  }

  shuffle<T>(arr: Array<T>): void {
    for (let i = arr.length - 1; i > 0; i--) {
      const j: number = this.int(i + 1);
      const tmp: T = arr[i];
      arr[i] = arr[j];
      arr[j] = tmp;
    }
  }
}

const secureRandom: SecureRandom = new SecureRandom();