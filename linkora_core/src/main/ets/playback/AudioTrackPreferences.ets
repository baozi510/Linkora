import { MediaSource } from '../models/MediaSource';
import { PortTrack, PortTrackKind } from './PlaybackPort';

export class AudioTrackPreferences {
  // ISO 639-2 B/T aliases: https://www.loc.gov/standards/iso639-2/ISO-639-2_utf-8.txt
  private static readonly languageAliases: Map<string, string> = new Map<string, string>([
    ['aar', 'aa'], ['abk', 'ab'], ['afr', 'af'], ['aka', 'ak'], ['alb', 'sq'],
    ['sqi', 'sq'], ['amh', 'am'], ['ara', 'ar'], ['arg', 'an'], ['arm', 'hy'],
    ['hye', 'hy'], ['asm', 'as'], ['ava', 'av'], ['ave', 'ae'], ['aym', 'ay'],
    ['aze', 'az'], ['bak', 'ba'], ['bam', 'bm'], ['baq', 'eu'], ['eus', 'eu'],
    ['bel', 'be'], ['ben', 'bn'], ['bis', 'bi'], ['bos', 'bs'], ['bre', 'br'],
    ['bul', 'bg'], ['bur', 'my'], ['mya', 'my'], ['cat', 'ca'], ['cha', 'ch'],
    ['che', 'ce'], ['chi', 'zh'], ['zho', 'zh'], ['chu', 'cu'], ['chv', 'cv'],
    ['cor', 'kw'], ['cos', 'co'], ['cre', 'cr'], ['cze', 'cs'], ['ces', 'cs'],
    ['dan', 'da'], ['div', 'dv'], ['dut', 'nl'], ['nld', 'nl'], ['dzo', 'dz'],
    ['eng', 'en'], ['epo', 'eo'], ['est', 'et'], ['ewe', 'ee'], ['fao', 'fo'],
    ['fij', 'fj'], ['fin', 'fi'], ['fre', 'fr'], ['fra', 'fr'], ['fry', 'fy'],
    ['ful', 'ff'], ['geo', 'ka'], ['kat', 'ka'], ['ger', 'de'], ['deu', 'de'],
    ['gla', 'gd'], ['gle', 'ga'], ['glg', 'gl'], ['glv', 'gv'], ['gre', 'el'],
    ['ell', 'el'], ['grn', 'gn'], ['guj', 'gu'], ['hat', 'ht'], ['hau', 'ha'],
    ['heb', 'he'], ['her', 'hz'], ['hin', 'hi'], ['hmo', 'ho'], ['hrv', 'hr'],
    ['hun', 'hu'], ['ibo', 'ig'], ['ice', 'is'], ['isl', 'is'], ['ido', 'io'],
    ['iii', 'ii'], ['iku', 'iu'], ['ile', 'ie'], ['ina', 'ia'], ['ind', 'id'],
    ['ipk', 'ik'], ['ita', 'it'], ['jav', 'jv'], ['jpn', 'ja'], ['kal', 'kl'],
    ['kan', 'kn'], ['kas', 'ks'], ['kau', 'kr'], ['kaz', 'kk'], ['khm', 'km'],
    ['kik', 'ki'], ['kin', 'rw'], ['kir', 'ky'], ['kom', 'kv'], ['kon', 'kg'],
    ['kor', 'ko'], ['kua', 'kj'], ['kur', 'ku'], ['lao', 'lo'], ['lat', 'la'],
    ['lav', 'lv'], ['lim', 'li'], ['lin', 'ln'], ['lit', 'lt'], ['ltz', 'lb'],
    ['lub', 'lu'], ['lug', 'lg'], ['mac', 'mk'], ['mkd', 'mk'], ['mah', 'mh'],
    ['mal', 'ml'], ['mao', 'mi'], ['mri', 'mi'], ['mar', 'mr'], ['may', 'ms'],
    ['msa', 'ms'], ['mlg', 'mg'], ['mlt', 'mt'], ['mon', 'mn'], ['nau', 'na'],
    ['nav', 'nv'], ['nbl', 'nr'], ['nde', 'nd'], ['ndo', 'ng'], ['nep', 'ne'],
    ['nno', 'nn'], ['nob', 'nb'], ['nor', 'no'], ['nya', 'ny'], ['oci', 'oc'],
    ['oji', 'oj'], ['ori', 'or'], ['orm', 'om'], ['oss', 'os'], ['pan', 'pa'],
    ['per', 'fa'], ['fas', 'fa'], ['pli', 'pi'], ['pol', 'pl'], ['por', 'pt'],
    ['pus', 'ps'], ['que', 'qu'], ['roh', 'rm'], ['rum', 'ro'], ['ron', 'ro'],
    ['run', 'rn'], ['rus', 'ru'], ['sag', 'sg'], ['san', 'sa'], ['sin', 'si'],
    ['slo', 'sk'], ['slk', 'sk'], ['slv', 'sl'], ['sme', 'se'], ['smo', 'sm'],
    ['sna', 'sn'], ['snd', 'sd'], ['som', 'so'], ['sot', 'st'], ['spa', 'es'],
    ['srd', 'sc'], ['srp', 'sr'], ['ssw', 'ss'], ['sun', 'su'], ['swa', 'sw'],
    ['swe', 'sv'], ['tah', 'ty'], ['tam', 'ta'], ['tat', 'tt'], ['tel', 'te'],
    ['tgk', 'tg'], ['tgl', 'tl'], ['tha', 'th'], ['tib', 'bo'], ['bod', 'bo'],
    ['tir', 'ti'], ['ton', 'to'], ['tsn', 'tn'], ['tso', 'ts'], ['tuk', 'tk'],
    ['tur', 'tr'], ['twi', 'tw'], ['uig', 'ug'], ['ukr', 'uk'], ['urd', 'ur'],
    ['uzb', 'uz'], ['ven', 've'], ['vie', 'vi'], ['vol', 'vo'], ['wel', 'cy'],
    ['cym', 'cy'], ['wln', 'wa'], ['wol', 'wo'], ['xho', 'xh'], ['yid', 'yi'],
    ['yor', 'yo'], ['zha', 'za'], ['zul', 'zu']
  ]);
  readonly languages: string[];
  readonly remember: boolean;

  constructor(languages: string[] = [], remember: boolean = true) {
    if (languages.length > 8) throw new Error('At most eight audio languages');
    this.languages = [];
    for (const value of languages) {
      const language: string = AudioTrackPreferences.language(value);
      if (!/^[a-z]{2,3}(-[a-z0-9]{2,8})*$/.test(language)) throw new Error('Invalid audio language');
      if (!this.languages.includes(language)) this.languages.push(language);
    }
    this.remember = remember;
  }

  static language(value: string): string {
    const parts: string[] = value.trim().toLowerCase().replace(/_/g, '-').split('-');
    // Container metadata commonly uses ISO 639-2; preferences use BCP 47 tags.
    parts[0] = AudioTrackPreferences.languageAliases.get(parts[0]) ?? parts[0];
    return parts[0] === 'und' ? '' : parts.join('-');
  }

  choose(tracks: PortTrack[], remembered: AudioTrackChoice | null): PortTrack | null {
    const audio: PortTrack[] = tracks.filter((track: PortTrack) => track.kind === PortTrackKind.AUDIO);
    const saved: PortTrack | null = this.remember ? remembered?.match(audio) ?? null : null;
    if (saved !== null) return saved;
    for (const language of this.languages) {
      let matches: PortTrack[] = audio.filter((track: PortTrack) =>
        AudioTrackPreferences.language(track.language) === language);
      if (matches.length === 0) matches = audio.filter((track: PortTrack) =>
        AudioTrackPreferences.language(track.language).split('-')[0] === language.split('-')[0]);
      if (matches.length > 0) return matches.find((track: PortTrack) => track.isDefault === true) ?? matches[0];
    }
    return null;
  }
}

export class AudioTrackChoice {
  readonly language: string;
  readonly title: string;
  readonly channels: number;

  constructor(language: string, title: string, channels: number) {
    this.language = AudioTrackPreferences.language(language);
    this.title = title.trim().slice(0, 256);
    this.channels = channels;
  }

  static from(track: PortTrack): AudioTrackChoice {
    return new AudioTrackChoice(track.language, track.title, track.channels);
  }

  match(tracks: PortTrack[]): PortTrack | null {
    if (this.language.length === 0 && this.title.length === 0) return null;
    let matches: PortTrack[] = tracks.filter((track: PortTrack) => track.kind === PortTrackKind.AUDIO &&
      AudioTrackPreferences.language(track.language) === this.language &&
      track.title.trim().slice(0, 256) === this.title);
    if (matches.length > 1 && this.channels > 0) matches = matches.filter((track: PortTrack) =>
      track.channels === this.channels);
    return matches.length === 1 ? matches[0] : null;
  }

  encode(): string {
    return JSON.stringify(this);
  }

  static decode(value: string): AudioTrackChoice | null {
    if (value.length > 4096) return null;
    try {
      const data: Record<string, Object> = JSON.parse(value) as Record<string, Object>;
      if (typeof data.language !== 'string' || data.language.length > 64 ||
        typeof data.title !== 'string' || data.title.length > 256 ||
        typeof data.channels !== 'number' || !Number.isInteger(data.channels) || data.channels < 0) return null;
      return new AudioTrackChoice(data.language, data.title, data.channels);
    } catch (_error) { return null; }
  }
}

export interface AudioTrackRepository {
  loadPreferences(): Promise<AudioTrackPreferences>;
  savePreferences(value: AudioTrackPreferences): Promise<void>;
  loadChoice(source: MediaSource): Promise<AudioTrackChoice | null>;
  saveChoice(source: MediaSource, value: AudioTrackChoice | null): Promise<void>;
}
