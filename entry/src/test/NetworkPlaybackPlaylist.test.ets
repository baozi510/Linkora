import { describe, expect, it } from '@ohos/hypium';
import { MediaSourceKind, RemoteProtocol } from 'linkora_core';
import { NetworkDirectoryEntry, NetworkDirectoryEntryKind } from '../main/ets/models/NetworkDirectoryState';
import { NetworkServerEntry } from '../main/ets/services/NetworkServerStore';
import { NetworkPlaybackPlaylist } from '../main/ets/services/NetworkPlaybackPlaylist';

function file(path: string, name: string): NetworkDirectoryEntry {
  return new NetworkDirectoryEntry(name, path, NetworkDirectoryEntryKind.FILE, 100, 123);
}

export default function networkPlaybackPlaylistTest(): void {
  describe('NetworkPlaybackPlaylist', () => {
    const server = new NetworkServerEntry(7, 'Fixture', RemoteProtocol.WEBDAV, 'localhost', 8080);

    it('keepsOnlyDirectVideoFilesAndLocatesTheSelectedVideo', 0, () => {
      const list = NetworkPlaybackPlaylist.build(server, '/tv/', [
        new NetworkDirectoryEntry('Sub', '/tv/sub/', NetworkDirectoryEntryKind.DIRECTORY),
        file('/tv/a.mp4', 'a.mp4'), file('/tv/poster.png', 'poster.png'),
        file('/tv/subtitle.srt', 'subtitle.srt'), file('/tv/song.flac', 'song.flac'),
        file('/tv/b.mkv', 'b.mkv'), file('/tv/notes.txt', 'notes.txt')
      ], '/tv/b.mkv', true);
      expect(list?.items.length).assertEqual(2);
      expect(list?.startIndex).assertEqual(1);
      expect(list?.currentItem()?.source.locator).assertEqual('/tv/b.mkv');
    });

    it('excludesDescendantsAndSiblingDirectoriesEvenIfReturnedByTheServer', 0, () => {
      const list = NetworkPlaybackPlaylist.build(server, '/tv/', [
        file('/tv/a.mp4', 'a.mp4'), file('/tv/sub/b.mp4', 'b.mp4'),
        file('/tv2/c.mp4', 'c.mp4'), file('/movie/d.mp4', 'd.mp4')
      ], '/tv/a.mp4', true);
      expect(list?.items.length).assertEqual(1);
    });

    it('handlesRootAndProviderRelativeDirectoryPaths', 0, () => {
      const root = NetworkPlaybackPlaylist.build(server, '/', [file('/a.mp4', 'a.mp4')], '/a.mp4', true);
      expect(root?.items.length).assertEqual(1);
      const relative = NetworkPlaybackPlaylist.build(server, 'Movies',
        [file('Movies/a.mp4', 'a.mp4'), file('Movies/Sub/b.mp4', 'b.mp4')], 'Movies/a.mp4', true);
      expect(relative?.items.length).assertEqual(1);
    });

    it('doesNotResortTheBrowserListing', 0, () => {
      const list = NetworkPlaybackPlaylist.build(server, '/tv', [
        file('/tv/b.mp4', 'b.mp4'), file('/tv/a.mp4', 'a.mp4')
      ], '/tv/a.mp4', true);
      expect(list?.items[0].source.displayName).assertEqual('b.mp4');
      expect(list?.startIndex).assertEqual(1);
    });

    it('deduplicatesPathsButKeepsDistinctPathsWithTheSameName', 0, () => {
      const list = NetworkPlaybackPlaylist.build(server, '/tv', [
        file('/tv/a.mp4', 'same.mp4'), file('/tv/a.mp4', 'same.mp4'),
        file('/tv/b.mp4', 'same.mp4')
      ], '/tv/b.mp4', true);
      expect(list?.items.length).assertEqual(2);
      expect(list?.startIndex).assertEqual(1);
    });

    it('keepsOriginalRemoteIdentityAndCredentialReferenceWithoutCreatingProxyUrls', 0, () => {
      const list = NetworkPlaybackPlaylist.build(server, '/tv',
        [file('/tv/第 02 集 #1.mkv', '第 02 集 #1.mkv')], '/tv/第 02 集 #1.mkv', true);
      expect(list?.currentItem()?.source.kind).assertEqual(MediaSourceKind.REMOTE_FILE);
      expect(list?.currentItem()?.source.locator).assertEqual('/tv/第 02 集 #1.mkv');
      expect(list?.currentItem()?.source.sourceId).assertEqual('network-server:7');
      expect(list?.currentItem()?.source.credentialRef).assertEqual('network-server:7');
      expect(list?.currentItem()?.source.sizeBytes).assertEqual(100);
    });

    it('isolatesIdenticalPathsOnDifferentServers', 0, () => {
      const other = new NetworkServerEntry(8, 'Other', RemoteProtocol.WEBDAV, 'localhost', 8080);
      const a = NetworkPlaybackPlaylist.build(server, '/tv', [file('/tv/a.mp4', 'a.mp4')], '/tv/a.mp4', true);
      const b = NetworkPlaybackPlaylist.build(other, '/tv', [file('/tv/a.mp4', 'a.mp4')], '/tv/a.mp4', true);
      expect(a?.currentItem()?.id === b?.currentItem()?.id).assertFalse();
    });

    it('doesNotOpenEmptyMissingOrNonVideoSelections', 0, () => {
      expect(NetworkPlaybackPlaylist.build(server, '/tv', [], '/tv/gone.mp4', true)).assertNull();
      expect(NetworkPlaybackPlaylist.build(server, '/tv', [file('/tv/a.mp4', 'a.mp4')], '/tv/gone.mp4', true))
        .assertNull();
      expect(NetworkPlaybackPlaylist.build(server, '/tv', [file('/tv/a.flac', 'a.flac')], '/tv/a.flac', true))
        .assertNull();
    });

    it('rejectsUnpersistedServerIdentityAndBlankLocators', 0, () => {
      const invalid = new NetworkServerEntry(0, 'Unsaved', RemoteProtocol.WEBDAV, 'localhost', 8080);
      expect(NetworkPlaybackPlaylist.build(invalid, '/', [file('/a.mp4', 'a.mp4')], '/a.mp4', true))
        .assertNull();
      expect(NetworkPlaybackPlaylist.build(server, '', [file('', 'a.mp4')], '', true)).assertNull();
    });

    it('retainsIncompleteStatusAndDetachesTheSnapshotFromListingChanges', 0, () => {
      const entries = [file('/tv/a.mp4', 'a.mp4'), file('/tv/b.mp4', 'b.mp4')];
      const list = NetworkPlaybackPlaylist.build(server, '/tv', entries, '/tv/a.mp4', false);
      entries.pop();
      expect(list?.complete).assertFalse();
      expect(list?.items.length).assertEqual(2);
    });
  });
}
