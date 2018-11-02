defmodule FunkAndSchuster.ArtTest do
  use FunkAndSchuster.DataCase

  alias FunkAndSchuster.Art

  describe "artists" do
    alias FunkAndSchuster.Art.Artist

    @valid_attrs %{dob: ~D[2010-04-17], first_name: "some first_name", last_name: "some last_name"}
    @update_attrs %{dob: ~D[2011-05-18], first_name: "some updated first_name", last_name: "some updated last_name"}
    @invalid_attrs %{dob: nil, first_name: nil, last_name: nil}

    def artist_fixture(attrs \\ %{}) do
      {:ok, artist} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Art.create_artist()

      artist
    end

    test "list_artists/0 returns all artists" do
      artist = artist_fixture()
      assert Art.list_artists() == [artist]
    end

    test "get_artist!/1 returns the artist with given id" do
      artist = artist_fixture()
      assert Art.get_artist!(artist.id) == artist
    end

    test "create_artist/1 with valid data creates a artist" do
      assert {:ok, %Artist{} = artist} = Art.create_artist(@valid_attrs)
      assert artist.dob == ~D[2010-04-17]
      assert artist.first_name == "some first_name"
      assert artist.last_name == "some last_name"
    end

    test "create_artist/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Art.create_artist(@invalid_attrs)
    end

    test "update_artist/2 with valid data updates the artist" do
      artist = artist_fixture()
      assert {:ok, artist} = Art.update_artist(artist, @update_attrs)
      assert %Artist{} = artist
      assert artist.dob == ~D[2011-05-18]
      assert artist.first_name == "some updated first_name"
      assert artist.last_name == "some updated last_name"
    end

    test "update_artist/2 with invalid data returns error changeset" do
      artist = artist_fixture()
      assert {:error, %Ecto.Changeset{}} = Art.update_artist(artist, @invalid_attrs)
      assert artist == Art.get_artist!(artist.id)
    end

    test "delete_artist/1 deletes the artist" do
      artist = artist_fixture()
      assert {:ok, %Artist{}} = Art.delete_artist(artist)
      assert_raise Ecto.NoResultsError, fn -> Art.get_artist!(artist.id) end
    end

    test "change_artist/1 returns a artist changeset" do
      artist = artist_fixture()
      assert %Ecto.Changeset{} = Art.change_artist(artist)
    end
  end

  describe "works" do
    alias FunkAndSchuster.Art.Work

    @valid_attrs %{date: ~D[2010-04-17], dimensions: "some dimensions", medium: "some medium", title: "some title"}
    @update_attrs %{date: ~D[2011-05-18], dimensions: "some updated dimensions", medium: "some updated medium", title: "some updated title"}
    @invalid_attrs %{date: nil, dimensions: nil, medium: nil, title: nil}

    def work_fixture(attrs \\ %{}) do
      {:ok, work} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Art.create_work()

      work
    end

    test "list_works/0 returns all works" do
      work = work_fixture()
      assert Art.list_works() == [work]
    end

    test "get_work!/1 returns the work with given id" do
      work = work_fixture()
      assert Art.get_work!(work.id) == work
    end

    test "create_work/1 with valid data creates a work" do
      assert {:ok, %Work{} = work} = Art.create_work(@valid_attrs)
      assert work.date == ~D[2010-04-17]
      assert work.dimensions == "some dimensions"
      assert work.medium == "some medium"
      assert work.title == "some title"
    end

    test "create_work/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Art.create_work(@invalid_attrs)
    end

    test "update_work/2 with valid data updates the work" do
      work = work_fixture()
      assert {:ok, work} = Art.update_work(work, @update_attrs)
      assert %Work{} = work
      assert work.date == ~D[2011-05-18]
      assert work.dimensions == "some updated dimensions"
      assert work.medium == "some updated medium"
      assert work.title == "some updated title"
    end

    test "update_work/2 with invalid data returns error changeset" do
      work = work_fixture()
      assert {:error, %Ecto.Changeset{}} = Art.update_work(work, @invalid_attrs)
      assert work == Art.get_work!(work.id)
    end

    test "delete_work/1 deletes the work" do
      work = work_fixture()
      assert {:ok, %Work{}} = Art.delete_work(work)
      assert_raise Ecto.NoResultsError, fn -> Art.get_work!(work.id) end
    end

    test "change_work/1 returns a work changeset" do
      work = work_fixture()
      assert %Ecto.Changeset{} = Art.change_work(work)
    end
  end
end
